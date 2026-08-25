package modding.custom.transitions;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import modding.custom.transitions.data.StickerPack;

class StickerOverlay extends flixel.FlxBasic {
	static inline var STICKER_COUNT:Int = 32;
	static inline var SPAWN_INTERVAL:Float = 0.02;
	static inline var REMOVE_INTERVAL:Float = 0.05;

	static var _instance:StickerOverlay;

	public static function instance():StickerOverlay {
		if (_instance == null) {
			_instance = new StickerOverlay();
			FlxG.plugins.addPlugin(_instance);
		}
		return _instance;
	}

	var pack:StickerPack;
	var stickers:FlxTypedGroup<FlxSprite>;
	var overlayCam:FlxCamera;

	var spawnQueue:Array<FlxSprite> = [];
	var spawnIndex:Int = 0;

	var isLeaving:Bool = false;
	var onCovered:Void->Void;
	var leaveCallback:Void->Void;
	var visibleStickers:Array<FlxSprite> = [];
	var removeIndex:Int = 0;

	var accumulator:Float = 0;

	function new() {
		super();
		visible = false;
		active = false;

		stickers = new FlxTypedGroup<FlxSprite>();
	}

	private function ensureCamera() {
		@:privateAccess
		if (overlayCam == null || overlayCam.flashSprite == null) {
			overlayCam = new FlxCamera();
			overlayCam.bgColor = 0x00000000;
		}

		var list = FlxG.cameras.list;

		if (!list.contains(overlayCam)) {
			FlxG.cameras.add(overlayCam, false);
		} else if (list.length > 1 && list[list.length - 1] != overlayCam) {
			FlxG.cameras.remove(overlayCam, false);
			FlxG.cameras.add(overlayCam, false);
		}
	}

	public function show(packName:String, ?onCovered:Void->Void) {
		ensureCamera();

		this.pack = new StickerPack(packName);
		this.onCovered = onCovered;
		isLeaving = false;
		leaveCallback = null;
		accumulator = SPAWN_INTERVAL;
		spawnIndex = 0;
		removeIndex = 0;
		visibleStickers = [];

		stickers.forEach(s -> s.kill());
		stickers.clear();
		spawnQueue = [];

		for (i in 0...STICKER_COUNT) {
			var id = pack.randomId();
			if (id == null)
				continue;

			var spr = new FlxSprite();
			spr.loadGraphic(pack.graphicPath(id));
			spr.scale.set(0.9, 0.9);
			spr.updateHitbox();
			spr.scrollFactor.set();
			spr.x = FlxG.random.float(-spr.width * 0.5, FlxG.width - spr.width * 0.5);
			spr.y = FlxG.random.float(-spr.height * 0.5, FlxG.height - spr.height * 0.5);
			spr.visible = false;
			spr.cameras = [overlayCam];
			stickers.add(spr);
			spawnQueue.push(spr);
		}

		visible = true;
		active = true;
	}

	public function leave(?callback:Void->Void) {
		if (isLeaving)
			return;

		ensureCamera();
		isLeaving = true;
		leaveCallback = callback;
		removeIndex = 0;
		accumulator = REMOVE_INTERVAL;

		visibleStickers = [];
		stickers.forEachAlive(function(spr:FlxSprite) {
			if (spr.visible)
				visibleStickers.push(spr);
		});

		if (visibleStickers.length == 0) {
			_finishLeave();
		}
	}

	override public function update(elapsed:Float) {
		if (!active)
			return;

		ensureCamera();

		accumulator += elapsed;

		var interval = isLeaving ? REMOVE_INTERVAL : SPAWN_INTERVAL;
		if (accumulator < interval)
			return;

		accumulator -= interval;

		if (!isLeaving)
			_stepSpawn();
		else
			_stepRemove();
	}

	override public function draw() {
		if (!visible)
			return;
		stickers.draw();
	}

	function _stepSpawn() {
		if (spawnIndex >= spawnQueue.length)
			return;

		spawnQueue[spawnIndex].visible = true;
		FlxG.sound.play(pack.randomClickSound());
		spawnIndex++;

		if (spawnIndex >= spawnQueue.length) {
			if (onCovered != null) {
				var callback = onCovered;
				onCovered = null;
				callback();
			}
		}
	}

	function _stepRemove() {
		if (removeIndex >= visibleStickers.length) {
			_finishLeave();
			return;
		}

		visibleStickers[removeIndex].visible = false;
		FlxG.sound.play(pack.randomClickSound());
		removeIndex++;

		if (removeIndex >= visibleStickers.length)
			_finishLeave();
	}

	function _finishLeave() {
		visible = false;
		active = false;
		stickers.forEach(s -> s.kill());
		stickers.clear();
		spawnQueue = [];
		visibleStickers = [];

		if (overlayCam != null) {
			FlxG.cameras.remove(overlayCam, true);
			overlayCam = null;
		}

		if (leaveCallback != null) {
			var callback = leaveCallback;
			leaveCallback = null;
			callback();
		}
	}

	override public function destroy() {
		if (overlayCam != null) {
			FlxG.cameras.remove(overlayCam, true);
			overlayCam = null;
		}

		stickers.clear();
		_instance = null;
		super.destroy();
	}
}

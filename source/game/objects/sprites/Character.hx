package game.objects.sprites;

import core.assets.FunkinSprite;
import core.json.objects.CharacterData;

class Character extends modding.scripting.types.sprites.ScriptedSpriteGroup {
	public static var parent:Character;

	public var curCharacter:String = 'bf';

	public var editorMode:Bool = false;

	public var characterData:CharacterData;
	public var layers:Array<FunkinSprite> = [];

	public var layerMap:Map<String, FunkinSprite> = new Map();

	public var layerGroup:flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxBasic> = null;

	public var isPlayer:Bool = false;
	public var isSing:Bool = false;
	public var isMiss:Bool = false;

	public var idleAfterSing:Bool = true;
	var isFlipXAnim:Bool = false;

	public var singCountTime:Float = 0;

	// is special animation yep
	public var isSpecial:Bool = false;

	public var cameraOffset:Point = {x: 0, y: 0};

	public var zIndex:Int = 0;
	public var danceEvery:Float = 1;
	public var characterId(get, never):String;
	public var cameraFocusPoint(get, never):flixel.math.FlxPoint;

	function get_characterId():String
		return curCharacter;

	function get_cameraFocusPoint():flixel.math.FlxPoint {
		var p = getCamPosition();
		return flixel.math.FlxPoint.weak(p.x, p.y);
	}

	public function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
		playAnim(name, restart);

	public var vslice:funkin.play.character.BaseCharacter = null;

	var _vsliceAnim:String = '';
	var _vsliceBroken:Map<String, Bool> = new Map();

	function vsliceFailed(method:String, e:Dynamic):Void {
		_vsliceBroken.set(method, true);
		Console.log('[V-Slice] $curCharacter.$method failed, using the engine one from now on: $e', true);
	}

	var _vsliceFinished:Bool = false;

	function attachVSlice():Void {
		detachVSlice();
		if (editorMode || !modding.vslice.VSlice.isActive() || !Std.isOfType(FlxG.state, game.PlayState))
			return;
		vslice = modding.vslice.VSliceScripts.attachCharacter(this);
		modding.vslice.VSliceHooks.register(vslice);
		modding.vslice.VSliceHooks.call(vslice, 'onCreate', modding.vslice.VSliceHooks.event('CREATE'));
	}

	function detachVSlice():Void {
		if (vslice == null)
			return;
		modding.vslice.VSliceHooks.call(vslice, 'onDestroy', modding.vslice.VSliceHooks.event('DESTROY'));
		modding.vslice.VSliceHooks.unregister(vslice);
		vslice.host = null;
		vslice = null;
	}

	var singTime:Float = 2;

	static final CHAR_ANIMS:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static function getCharAnim(direction:Int):String {
		return CHAR_ANIMS[direction % CHAR_ANIMS.length];
	}

	public function new(id:String, ?curCharacter:String = 'bf', ?x:Float = 0, ?y:Float = 0) {
		super(id, x, y);
		parent = this;
		this.curCharacter = curCharacter;
		#if HSCRIPT_ALLOWED
		initScript('characters/$curCharacter');
		#end
		loadSprite();
	}

	public function loadSprite() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onCreateSprite', []))
			return;
		#end

		switch (curCharacter) {
			// case 'bf':  hardcoder reference!1
			default:
				var charPath:String = 'data/characters/$curCharacter';
				if (!Paths.exists('$charPath.json')) {
					Console.log('[Character] WARNING: No character data found for "$curCharacter" and it will be replaced to bf.json');
					charPath = 'data/characters/bf';
				}

				characterData = modding.vslice.VSliceCharacters.readCharacter(Paths.getPath(charPath, JSON));

				if (characterData != null && (characterData.render == null || characterData.gameplay == null)) {
					Console.log('[Character] WARNING: "$curCharacter" is not a character format the engine reads, using bf', true);
					charPath = 'data/characters/bf';
					characterData = modding.vslice.VSliceCharacters.readCharacter(Paths.getPath(charPath, JSON));
				}

				if (characterData == null) {
					Console.log('[Character] WARNING: Character data was null, creating Dummy character', true);
					characterData = FormatJson.getCharDataPlaceholder();
				}

				idleAfterSing = characterData.gameplay.idleAfterSing ?? true;
				singTime = characterData.gameplay.singTime ?? 2;

				var camOff = characterData.gameplay.cameraOffset;
				cameraOffset = {
					x: camOff != null ? (camOff[0] ?? 0) : 0,
					y: camOff != null ? (camOff[1] ?? 0) : 0
				};

				var gameplayPos = characterData.gameplay.position;
				if (gameplayPos != null)
					setPosition(gameplayPos[0] ?? 0, gameplayPos[1] ?? 0);

				if (characterData.render.layers != null) {
					for (layer in characterData.render.layers) {
						var sprite = new FunkinSprite(0, 0);
						sprite.loadProps(layer, 'game/characters');
						layers.push(sprite);

						if (layer.name != null)
							layerMap.set(layer.name, sprite);
					}
				}
		}

		applyPlayerFlip();
		attachVSlice();

		#if HSCRIPT_ALLOWED
		script.call('postCreate', []);
		#end
	}

	public function applyPlayerFlip():Void {
		if (isPlayer && characterData?.meta?.flipAsPlayer == true)
			for (layer in layers)
				layer.flipX = !layer.flipX;
	}

	public function getLayer(name:String):FunkinSprite {
		return layerMap.get(name);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!editorMode) {
			for (i in 0...layers.length) {
				layers[i].setPosition(x + (characterData.render.layers[i].position ?? [0.0, 0.0])[0],
					y + (characterData.render.layers[i].position ?? [0.0, 0.0])[1]);
			}
		}

		if (isSpecial && layers.length > 0) {
			var cur = layers[0].currentAnim;
			if (cur != specialAnimName) {
				isSpecial = false;
				specialAnimName = null;
			} else if (layers[0].isFinished(cur)) {
				isSpecial = false;
				specialAnimName = null;
				dance();
			}
		}

		if ((isSing || isMiss) && !isSpecial)
			singCountTime += elapsed;

		if (vslice != null && layers.length > 0) {
			var cur = layers[0].currentAnim;
			if (cur != _vsliceAnim) {
				_vsliceAnim = cur;
				_vsliceFinished = false;
			}
			var finished = cur != null && cur != '' && layers[0].isFinished(cur);
			if (finished && !_vsliceFinished)
				modding.vslice.VSliceHooks.call(vslice, 'onAnimationFinished', cur);
			_vsliceFinished = finished;
		}

		if ((isSing || isMiss) && !isSpecial) {
			var beatLengthSecs = core.rhythm.RhythmCore.crochet / 1000.0;
			if (singCountTime >= singTime * beatLengthSecs) {
				isSing = false;
				isMiss = false;
				singCountTime = 0;
			}
		}

		#if HSCRIPT_ALLOWED
		script.call('postUpdate', [elapsed]);
		#end
	}

	public function changeCharacter(newCharacter:String):Void {
		if (newCharacter == curCharacter)
			return;

		var layerCameras:Array<flixel.FlxCamera> = null;
		for (layer in layers) {
			if (layer != null) {
				layerCameras = layer.cameras;
				break;
			}
		}

		for (layer in layers) {
			if (layer != null) {
				if (layerGroup != null)
					layerGroup.remove(layer, true);
				layer.kill();
				layer.destroy();
			}
		}
		layers = [];
		layerMap.clear();

		curCharacter = newCharacter;
		setPosition(0, 0);
		isDancing = false;
		bopAnimExists = false;
		isSpecial = false;
		isSing = false;
		isMiss = false;
		singCountTime = 0;

		#if HSCRIPT_ALLOWED
		if (script != null)
			script.destroy();
		initScript('characters/$curCharacter');
		#end

		loadSprite();

		if (layerGroup != null) {
			var at:Int = layerGroup.members.indexOf(this);
			for (layer in layers) {
				if (layerCameras != null)
					layer.cameras = layerCameras;
				if (at >= 0) {
					layerGroup.insert(at, layer);
					at++;
				} else
					layerGroup.add(layer);
			}
		}
	}

	var specialAnimName:String = null;

	public function playSpecialAnim(animKey:String):Bool {
		var data:Dynamic = characterData?.gameplay?.specialAnims != null ? Reflect.field(characterData.gameplay.specialAnims, animKey) : null;
		var animName:String = data != null ? data.anim : animKey;
		if (animName == null || !existsAnim(animName))
			return false;

		var canInterrupt = data != null ? (data.interrupt ?? false) : true;
		if (!canInterrupt && (isSing || isMiss))
			return false;

		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onSpecialAnim', [animKey, animName]))
			return false;
		#end

		var force = data != null ? (data.force ?? true) : true;
		playAnim(animName, force);
		isSpecial = true;
		isSing = false;
		isMiss = false;
		singCountTime = 0;
		specialAnimName = layers.length > 0 ? layers[0].currentAnim : animName;

		#if HSCRIPT_ALLOWED
		script.call('postSpecialAnim', [animKey, animName]);
		#end

		return true;
	}

	override public function playAnim(name:String, ?force:Bool = true) {
		if (vslice != null && !_vsliceBroken.exists('playAnimation')) {
			_vsliceAnim = '';
			try {
				vslice.playAnimation(name, force);
				return;
			} catch (e:Dynamic) {
				vsliceFailed('playAnimation', e);
			}
		}
		playAnimRaw(name, force);
	}

	public function playAnimRaw(name:String, ?force:Bool = true) {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onPlayAnim', [name, force]))
			return;
		#end

		if (characterData.render.layers != null) {
			for (layer in layers)
				layer.playAnim(name, force);

			for (layer in characterData.render.layers) {
				for (anim in layer.anims) {
					if (anim.name == name) {
						isFlipXAnim = anim.flipX;
						if (flipX != isFlipXAnim)
							flipX = isFlipXAnim;
						break;
					}
				}
			}
		}
	}

	override public function isFinished(anim:String):Bool {
		if (layers == null || layers.length == 0)
			return false;
		return layers[0].isFinished(anim);
	}

	public function getCamPosition():Point {
		var off = cameraOffset;
		var mid = (layers != null && layers.length > 0) ? layers[0].getMidpoint() : getMidpoint();
		return {
			x: mid.x + (off != null ? off.x : 0.0),
			y: mid.y + (off != null ? off.y : 0.0)
		};
	}

	var isDancing:Bool = false;
	var bopAnimExists:Bool = false;

	override public function dance() {
		if (isSpecial || isMiss || (!idleAfterSing || isSing) || singCountTime > 0)
			return;

		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onDance', []))
			return;
		#end

		if (vslice != null && !_vsliceBroken.exists('dance')) {
			try {
				vslice.dance(false);
				return;
			} catch (e:Dynamic) {
				vsliceFailed('dance', e);
			}
		}

		for (layer in characterData.render.layers) {
			if (layer.bopAnims != null) {
				if (existsAnim(layer.bopAnims[0])) {
					bopAnimExists = true;
					playAnim(layer.bopAnims[0]);
				}
			}
		}

		if (bopAnimExists)
			return;

		if (existsAnim('danceLeft') && existsAnim('danceRight')) {
			isDancing = !isDancing;
			playAnim(isDancing ? 'danceLeft' : 'danceRight', true);
		} else if (existsAnim('idle'))
			playAnim('idle', false);
	}

	override public function existsAnim(name:String):Bool {
		if (layers == null || layers.length == 0)
			return false;
		return layers[0].existsAnim(name);
	}

	override public function destroy() {
		detachVSlice();
		for (layer in layers)
			layer.destroy();
		layers = [];
		if (parent == this)
			parent = null;
		layerMap = null;
		super.destroy();
	};
}

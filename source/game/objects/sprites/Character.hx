package game.objects.sprites;

import utils.UtilsData;
import core.assets.FunkinSprite;
import core.json.objects.CharacterData;
import core.assets.FunkinObjectRegistry;
#if HSCRIPT_ALLOWED
import core.scripting.ScriptHandler;
#end

class Character extends FunkinObjectRegistry {
	public var curCharacter:String = 'bf';

	public var characterData:CharacterData;
	public var layers:Array<FunkinSprite> = [];
	public var isPlayer:Bool = false;
	public var isSing:Bool = false;
	public var isMiss:Bool = false;

	var idleAfterSing:Bool = true;
	var isFlipXAnim:Bool = false;

	public var singCountTime:Float = 0;

	public var cameraOffset:Point = {x: 0, y: 0};

	var singTime:Float = 4;

	static final CHAR_ANIMS:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	#if HSCRIPT_ALLOWED
	public var charScript:ScriptHandler;
	#end

	public static function getCharAnim(direction:Int):String {
		return CHAR_ANIMS[direction % CHAR_ANIMS.length];
	}

	public function new(id:String, ?curCharacter:String = 'bf', ?x:Float = 0, ?y:Float = 0) {
		super(id, x, y);
		this.curCharacter = curCharacter;
		loadSprite();
		#if HSCRIPT_ALLOWED
		initCharScript();
		#end
	}

	#if HSCRIPT_ALLOWED
	public function initCharScript():Void {
		charScript = new ScriptHandler(this);
		charScript.load(Paths.getPath('characters/$curCharacter', 'script'));
		charScript.executeAll();
		charScript.call('onCreate', []);
	}
	#end

	public function loadSprite() {
		switch (curCharacter) {
			default:
				var charData:String = Paths.getPath('data/characters/' + curCharacter, "json");
				characterData = UtilsData.readJson(charData);
				idleAfterSing = characterData.gameplay.idleAfterSing ?? true;
				singTime = characterData.gameplay.singTime ?? 4;
				cameraOffset = {
					x: characterData.gameplay.cameraOffset != null ? characterData.gameplay.cameraOffset[0] : 0,
					y: characterData.gameplay.cameraOffset != null ? characterData.gameplay.cameraOffset[1] : 0
				};

				if (characterData.gameplay.position != null)
					setPosition(characterData.gameplay.position[0], characterData.gameplay.position[1]);

				for (layer in characterData.render.layers) {
					var sprite = new FunkinSprite(0, 0);
					sprite.loadProps(layer, 'game/characters');
					layers.push(sprite);
				}
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		#if HSCRIPT_ALLOWED
		charScript.call('onUpdate', [elapsed]);
		#end

		for (i in 0...layers.length) {
			layers[i].setPosition(x + (characterData.render.layers[i].position ?? [0.0, 0.0])[0],
				y + (characterData.render.layers[i].position ?? [0.0, 0.0])[1]);
		}

		if (isSing || isMiss)
			singCountTime += elapsed;

		if (idleAfterSing && (isSing || isMiss)) {
			var beatLengthSecs = core.rhythm.RhythmCore.crochet / 1000.0;
			if (singCountTime >= singTime * beatLengthSecs) {
				isSing = false;
				isMiss = false;
				singCountTime = 0;
				dance();
			}
		}

		#if HSCRIPT_ALLOWED
		charScript.call('postUpdate', [elapsed]);
		#end
	}

	override public function playAnim(name:String, ?force:Bool = true) {
		#if HSCRIPT_ALLOWED
		if (charScript.callCancellable('onPlayAnim', [name, force]))
			return;
		#end
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
		#if HSCRIPT_ALLOWED
		if (charScript.callCancellable('onDance', []))
			return;
		#end

		if (isSing || isMiss)
			return;

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
			playAnim(isDancing ? 'danceLeft' : 'danceRight', false);
		} else if (existsAnim('idle'))
			playAnim('idle', false);
	}

	override public function existsAnim(name:String):Bool {
		if (layers == null || layers.length == 0)
			return false;
		return layers[0].existsAnim(name);
	}

	override public function destroy() {
		#if HSCRIPT_ALLOWED
		charScript.call('onDestroy', []);
		charScript.destroy();
		charScript = null;
		#end
		for (layer in layers)
			layer.destroy();
		layers = [];
		super.destroy();
	};
}

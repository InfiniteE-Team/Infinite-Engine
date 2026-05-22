package game.objects.sprites;

import utils.UtilsData;
import core.assets.FunkinSprite;
import core.json.objects.CharacterData;
import core.assets.FunkinObjectRegistry;

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

	public static function getCharAnim(direction:Int):String {
		return CHAR_ANIMS[direction % CHAR_ANIMS.length];
	}

	public function new(id:String, ?curCharacter:String = 'bf', ?x:Float = 0, ?y:Float = 0) {
		super(id, x, y);
		this.curCharacter = curCharacter;
		graphicLoad();
	}

	public function graphicLoad() {
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
			sprite.loadProps(layer, 'characters');
			layers.push(sprite);
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		for (i in 0...layers.length) {
			layers[i].setPosition(x + (characterData.render.layers[i].position ?? [0.0, 0.0])[0],
				y + (characterData.render.layers[i].position ?? [0.0, 0.0])[1]);
		}

		if (isSing || isMiss)
			singCountTime += elapsed;

		if (idleAfterSing && ((isMiss || isSing) && layers[0].animation.finished)) {
			isSing = false;
			isMiss = false;
			dance();
		}
	}

	override public function playAnim(name:String, ?force:Bool = true) {
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

	override public function dance() {
		if (isSing || isMiss && singCountTime > singTime) {
			singCountTime = 0;
			return;
		}

		if (existsAnim('danceLeft') && existsAnim('danceRight')) {
			isDancing = !isDancing;
			playAnim(isDancing ? 'danceLeft' : 'danceRight', false);
		} else
			playAnim('idle', false);
	}

	override public function existsAnim(name:String):Bool {
		if (layers == null || layers.length == 0)
			return false;
		return layers[0].existsAnim(name);
	}

	override public function destroy() {
		for (layer in layers)
			layer.destroy();
		layers = [];
		super.destroy();
	};
}

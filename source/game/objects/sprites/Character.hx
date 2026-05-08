package game.objects.sprites;

import core.json.objects.CharacterData;
import core.assets.FunkinSprite;
import core.assets.FunkinObjectRegistry;

class Character extends FunkinObjectRegistry {
	public var curCharacter:String = 'bf';

	var characterData:CharacterData;
	var layers:Array<FunkinSprite> = [];
	public var isPlayer:Bool = false;
    public var isSing:Bool = false;

	var isFlipXAnim:Bool = false;

	public function new(id:String, ?curCharacter:String = 'bf', ?x:Float = 0, ?y:Float = 0) {
		super(id, x, y);
		this.curCharacter = curCharacter;
		graphicLoad();
	}

	public function graphicLoad() {
		var charData:Null<String> = Paths.getPath('characters/' + curCharacter, "json");
		if (!sys.FileSystem.exists(charData))
			return;

		characterData = cast haxe.Json.parse(sys.io.File.getContent(charData));

		for (layer in characterData.render.layers) {
			var sprite = new FunkinSprite(x + layer.position[0], y + layer.position[1]);
			sprite.frames = Paths.getPath('characters/${layer.path}', "animated");

			for (anim in layer.anims)
				sprite.animation.addByPrefix(anim.name, anim.prefix, anim.framerate, anim.looped, anim.flipX, anim.flipY);
			sprite.scale.set(layer.scale[0], layer.scale[1]);
			sprite.alpha = layer.alpha;
			sprite.antialiasing = layer.antialiasing;
			sprite.flipX = layer.flipX;
			sprite.flipY = layer.flipY;
			sprite.visible = layer.visible;
			updateHitbox();

			layers.push(sprite);
		}
	}

	public static function spawn(id:String, ?charName:String = 'bf', ?x:Float = 0, ?y:Float = 0):Character {
		if (FunkinObjectRegistry.existsId(id)) {
			// character exists yep
			return cast FunkinObjectRegistry.get(id);
		}

		var char = new Character(id, charName, x, y);
		for (layer in char.layers)
			PlayState.instance.add(layer);
		PlayState.instance.add(char);
		return char;
	}

	public static function removeChar(id:String):Void {
		var char = fetch(id);
		if (char == null)
			return;

		for (layer in char.layers) {
			PlayState.instance.remove(layer);
			layer.destroy();
		}

		PlayState.instance.remove(char);
		char.destroy();
	}

	public static function fetch(id:String):Character {
		return cast FunkinObjectRegistry.get(id);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		for (i in 0...layers.length) {
			layers[i].setPosition(x + characterData.render.layers[i].position[0], y + characterData.render.layers[i].position[1]);
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

	var isDancing:Bool = false;

	public function dance() {
        if (isSing)
            return;

		if (existsAnim('danceLeft') && existsAnim('danceRight')) {
			isDancing = !isDancing;
			playAnim(isDancing ? 'danceLeft' : 'danceRight', false);
		} 
        else
			playAnim('idle', false);
	}

	override public function destroy() {
		super.destroy();
	};
}

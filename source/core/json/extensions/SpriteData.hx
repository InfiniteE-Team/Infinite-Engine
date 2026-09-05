package core.json.extensions;

import haxe.extern.EitherType;

// Data for sprites objects
typedef ObjectData = {
	var name:String;
	var ?path:String;
	var ?position:Array<Float>;

	var ?scale:Array<Float>;
	var ?alpha:Float;
	var ?visible:Bool;

	var ?flipX:Bool;
	var ?flipY:Bool;

	var ?angle:Float;

	var ?active:Bool;

	var ?scrollFactor:Array<Float>;

	var ?color:String;

	var ?antialiasing:Bool;

	// shaders for sprites
	var ?blend:String;
	var ?shader:String;

	var ?anims:Array<AnimData>;

	var ?firstAnim:String;

	var ?frameScale:Array<Int>;

	var ?bopAnims:Array<String>;
}

// Data for anims
typedef AnimData = {
	var ?offsets:Array<Float>;
	var name:String;

	var ?filePath:EitherType<String, Array<String>>;

	var ?shaderColor:Array<{r:Array<String>, g:Array<String>, b:Array<String>}>;

	var ?looped:Bool;
	var ?framerate:Float;

	var ?prefix:String;

	var ?indices:Array<Int>;

	var ?flipX:Bool;

	var ?flipY:Bool;

	var ?frameScale:Array<Int>;

	var ?suffix:String;
}

class SpriteData {
	public function new() {}

	public static function loadVar(sprite:core.assets.FunkinSprite, data:ObjectData):Void {
		if (sprite == null || data == null)
			return;

		if (data.position != null) {
			if (data.position.length >= 2)
				sprite.setPosition(data.position[0], data.position[1]);
		}
		if (data.scale != null) {
			if (data.scale.length >= 2) {
				sprite.scale.set(data.scale[0], data.scale[1]);
				sprite.updateHitbox();
			} else if (data.scale.length == 1) {
				sprite.scale.set(data.scale[0], data.scale[0]);
				sprite.updateHitbox();
			}
		}
		if (data.alpha != null)
			sprite.alpha = data.alpha;
		if (data.visible != null)
			sprite.visible = data.visible;
		if (data.flipX != null)
			sprite.flipX = data.flipX;
		if (data.flipY != null)
			sprite.flipY = data.flipY;
		if (data.angle != null)
			sprite.angle = data.angle;
		if (data.active != null)
			sprite.active = data.active;
		if (data.antialiasing != null)
			sprite.antialiasing = data.antialiasing;

		if (data.scrollFactor != null && data.scrollFactor.length >= 2)
			sprite.scrollFactor.set(data.scrollFactor[0], data.scrollFactor[1]);

		if (data.color != null) {
			var parsed = flixel.util.FlxColor.fromString(data.color);
			if (parsed != null)
				sprite.color = parsed;
		}
		if (data.firstAnim != null)
			sprite.playAnim(data.firstAnim, true);
	}
}

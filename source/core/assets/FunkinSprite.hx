package core.assets;

import animate.FlxAnimate;
import flixel.math.FlxPoint;
import core.json.extensions.SpriteData.ObjectData;
import flixel.graphics.frames.FlxAtlasFrames;

class FunkinSprite extends FlxAnimate {
	public var offsets:Map<String, FlxPoint> = new Map();

	private static var cache = new Map<String, FlxAtlasFrames>();

	override public function updateHitbox() {
		super.updateHitbox();
	}

	public function loadProps(props:ObjectData, path:String):Void {
		if (props.path != null){
			if (!cache.exists(props.path))
				cache.set(props.path, Paths.getPath('$path/${props.path}', "animated"));
			frames = cache.get(props.path);
		}

		if (props.position != null)
			setPosition(x + props.position[0], y + props.position[1]);
		if (props.scale != null)
			scale.set(props.scale[0], props.scale[1]);
		if (props.alpha != null)
			alpha = props.alpha;
		if (props.visible != null)
			visible = props.visible;
		if (props.flipX != null)
			flipX = props.flipX;
		if (props.flipY != null)
			flipY = props.flipY;
		if (props.antialiasing != null)
			antialiasing = props.antialiasing;

		for (anim in props.anims) {
			if (anim.filePath != null) {
				var paths:Array<String> = (anim.filePath is Array) ? cast anim.filePath : [cast anim.filePath];
				for (p in paths){
					if (!cache.exists(p))
						cache.set(p, Paths.getPath('$path/$p', "animated"));
				}
				frames = cache.get(paths[0]);
			}

			anim.indices?.length > 0 ? animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.framerate,
				anim.looped) : animation.addByPrefix(anim.name, anim.prefix, anim.framerate, anim.looped, anim.flipX, anim.flipY);
		}

		updateHitbox();
	}

	public function playAnim(name:Null<String>, ?force:Bool = true) {
		if (!existsAnim(name)) {
			trace('$name Anim Not Existed! ERROR');
			return;
		}

		animation.play(name, force);
		activeOffsets(getAnimOffset());
	}

	public static function clearCache()
	{
		for (key => frames in cache) {
        	frames.destroy();
    	}
    	cache.clear();
	}

	public function getAnimOffset():FlxPoint
		return offsets.get(anim.name) ?? new FlxPoint();

	public function existsAnim(anim:String):Bool
		return animation.exists(anim);

	public function isFinished(anim:String):Bool
		return animation.curAnim.finished && existsAnim(anim);

	public function activeOffsets(off:FlxPoint) {
		offset.set(off.x,off.y);
	}

	override public function destroy()
	{
		super.destroy();
	}

	public function dance() {}
}

package funkin.util.assets;

// V-Slice FlxAnimationUtil for scripts: registers V-Slice animation data on a sprite (atlas or sparrow) -JloorDev
@:keep
class FlxAnimationUtil {
	public static function addTextureAtlasAnimations(target:Dynamic, animations:Array<Dynamic>):Void {
		if (target == null || animations == null)
			return;
		for (a in animations) {
			var indices:Array<Int> = a.frameIndices;
			var fps:Float = a.frameRate ?? 24;
			var looped:Bool = a.looped == true;
			try {
				if (indices != null && indices.length > 0)
					target.anim.addByFrameLabelIndices(a.name, a.prefix, indices, fps, looped);
				else
					target.anim.addByFrameLabel(a.name, a.prefix, fps, looped);
			} catch (e:Dynamic) {
				target.anim.addBySymbol(a.name, a.prefix, fps, looped);
			}
		}
	}

	public static function addAtlasAnimations(target:Dynamic, animations:Array<Dynamic>):Void {
		if (target == null || animations == null)
			return;
		for (a in animations) {
			var indices:Array<Int> = a.frameIndices;
			if (indices != null && indices.length > 0)
				target.animation.addByIndices(a.name, a.prefix, indices, '', a.frameRate ?? 24, a.looped == true);
			else
				target.animation.addByPrefix(a.name, a.prefix, a.frameRate ?? 24, a.looped == true);
		}
	}
}

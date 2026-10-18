package funkin.util;

import flixel.tweens.FlxTween;

// V-Slice FlxTweenUtil for scripts that hold their tweens while paused -JloorDev
@:keep
class FlxTweenUtil {
	public static function pauseTweensOf(object:Dynamic, ?fieldPaths:Array<String>):Void
		@:privateAccess FlxTween.globalManager.forEachTweensOf(object, fieldPaths, t -> t.active = false);

	public static function resumeTweensOf(object:Dynamic, ?fieldPaths:Array<String>):Void
		@:privateAccess FlxTween.globalManager.forEachTweensOf(object, fieldPaths, t -> t.active = true);
}

package funkin.ui;

import flixel.math.FlxPoint;

// V-Slice FullScreenScaleMode for scripts: the engine is plain 16:9, so no widescreen scaling or cutout -JloorDev
@:keep
class FullScreenScaleMode {
	public static var wideScale:FlxPoint = FlxPoint.get(1, 1);
	public static var gameCutoutSize:FlxPoint = FlxPoint.get(0, 0);
	public static var cutoutSize:FlxPoint = FlxPoint.get(0, 0);
}

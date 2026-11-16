package funkin.util.plugins;

import flixel.FlxBasic;

// the engine handles the volume keys itself, this is only here so scripts can find and remove it -JloorDev
class VolumePlugin extends FlxBasic {
	public static function initialize():Void {
		for (p in FlxG.plugins.list)
			if (Std.isOfType(p, VolumePlugin))
				return;
		FlxG.plugins.add(new VolumePlugin());
	}
}

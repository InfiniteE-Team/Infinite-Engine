package funkin.compat;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

// bits of V-Slice's flixel fork that scripts expect, the script loader points the calls here -JloorDev
@:keep
class FlxCompat {
	// inline in flixel, so scripts can't call it -JloorDev
	public static function fromString(s:String):Int
		return FlxKey.fromString(s);

	// V-Slice keybinds come padded with 0 and flixel throws on it -JloorDev
	public static function anyJustPressed(keys:Array<Int>):Bool
		return keys != null && FlxG.keys.anyJustPressed(validKeys(keys));

	public static function anyPressed(keys:Array<Int>):Bool
		return keys != null && FlxG.keys.anyPressed(validKeys(keys));

	public static function anyJustReleased(keys:Array<Int>):Bool
		return keys != null && FlxG.keys.anyJustReleased(validKeys(keys));

	static function validKeys(keys:Array<Int>):Array<Int>
		return [for (k in keys) if (k > 0) k];

	// every object has zIndex there, here only some do -JloorDev
	public static function setZIndex(obj:Dynamic, v:Int):Void {
		if (obj == null)
			return;
		try
			Reflect.setProperty(obj, 'zIndex', v)
		catch (_:Dynamic) {}
	}
}

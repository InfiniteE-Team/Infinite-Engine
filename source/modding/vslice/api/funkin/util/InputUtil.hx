package funkin.util;

@:keep
class InputUtil {
	public static function getKeyName(key:Int):String
		return flixel.input.keyboard.FlxKey.toStringMap.get(key) ?? '';
}

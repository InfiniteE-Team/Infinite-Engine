package funkin.util;

import flixel.FlxG;
import flixel.FlxBasic;

// V-Slice reads the mouse through this off mobile, so mods like Baldi's keypad work with a click -JloorDev
@:keep
class TouchUtil {
	public static var touch(get, never):Dynamic;
	public static var pressed(get, never):Bool;
	public static var justPressed(get, never):Bool;
	public static var justReleased(get, never):Bool;
	public static var justMoved(get, never):Bool;

	static function get_touch():Dynamic
		return FlxG.mouse;

	static function get_pressed():Bool
		return FlxG.mouse.pressed;

	static function get_justPressed():Bool
		return FlxG.mouse.justPressed;

	static function get_justReleased():Bool
		return FlxG.mouse.justReleased;

	static function get_justMoved():Bool
		return FlxG.mouse.justMoved;

	public static function overlaps(object:FlxBasic, ?camera:flixel.FlxCamera):Bool
		return object != null && FlxG.mouse.overlaps(object, camera);

	public static function overlapsComplex(object:FlxBasic, ?camera:flixel.FlxCamera):Bool
		return overlaps(object, camera);
}

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

	// flixel builds the next state a frame later, outside any try, so a script state that can't be built would crash the game -JloorDev
	public static function switchState(next:Dynamic):Void {
		var state:flixel.FlxState = null;
		try
			state = Reflect.isFunction(next) ? next() : next
		catch (e:Dynamic) {
			Console.log('[V-Slice] a script tried to switch to a state the engine can\'t build: $e', true);
			return;
		}
		if (state != null)
			FlxG.switchState(() -> state);
	}

	// V-Slice plays the instrumental as FlxG.sound.music (Baldi's clock reads it), here it's in gameAudio -JloorDev
	public static var music(get, never):flixel.sound.FlxSound;

	static function get_music():flixel.sound.FlxSound
		return game.PlayState.instance?.gameAudio?.inst ?? FlxG.sound.music;

	// every object has zIndex there, here only some do -JloorDev
	public static function setZIndex(obj:Dynamic, v:Int):Void {
		if (obj == null)
			return;
		try
			Reflect.setProperty(obj, 'zIndex', v)
		catch (_:Dynamic) {}
	}
}

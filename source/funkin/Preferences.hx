package funkin;

// V-Slice Preferences for scripts, from the engine's save where it has the same option -JloorDev
@:keep
class Preferences {
	public static var downscroll(get, never):Bool;
	public static var flashingLights(get, never):Bool;
	public static var subtitles:Bool = false;
	public static var naughtyness:Bool = true;
	public static var autoPause:Bool = true;
	public static var zoomCamera:Bool = true;
	public static var debugDisplay:Bool = false;
	public static var controlsScheme:String = 'arrows';
	public static var strumlineBackgroundOpacity:Float = 0;

	static function get_downscroll():Bool
		return SaveData.data.downscroll == true;

	static function get_flashingLights():Bool
		return Reflect.field(SaveData.data, 'flashingLights') != false;
}

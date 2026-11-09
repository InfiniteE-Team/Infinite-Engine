package funkin.util;

// no haptics on desktop -JloorDev
@:keep
class HapticUtil {
	public static var hapticsAvailable:Bool = false;

	public static function vibrate(?period:Float, ?duration:Float, ?amplitude:Float, ?sharpness:Float):Void {}

	public static function vibrateByPreset(?preset:Dynamic):Void {}
}

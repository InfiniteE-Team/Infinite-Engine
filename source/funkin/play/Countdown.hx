package funkin.play;

// V-Slice Countdown statics for scripts; the engine runs its own countdown -JloorDev
@:keep
class Countdown {
	public static var skipCountdown:Bool = false;

	public static function stopCountdown():Void {}

	public static function pauseCountdown():Void {}

	public static function resumeCountdown():Void {}
}

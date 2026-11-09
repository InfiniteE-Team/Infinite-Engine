package funkin.play;

// V-Slice GameOverSubState for scripts: instance exists while the engine's game over is open -JloorDev
@:keep
class GameOverSubState {
	public static var instance:GameOverSubState = null;
	public static var blueballed:Bool = false;
	public static var blueBallSuffix:String = '';
	public static var musicSuffix:String = '';
	public static var animationSuffix:String = '';

	public var engine:Dynamic;
	public var mustNotExit:Bool = false;
	public var gameOverMusic:flixel.sound.FlxSound = null;

	public function new(engine:Dynamic) {
		this.engine = engine;
	}

	public static function playBlueBalledSFX():Void {}

	public static function reset():Void {
		blueBallSuffix = '';
		musicSuffix = '';
		animationSuffix = '';
	}

	public function startDeathMusic(?startingVolume:Float, ?force:Bool):Void {}

	public function resetCameraZoom():Void {}
}

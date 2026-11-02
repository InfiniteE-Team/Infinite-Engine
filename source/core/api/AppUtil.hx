package core.api;

class AppUtil {
	public static function updateFramerate(value:Int) {
		FlxG.updateFramerate = value;
		FlxG.drawFramerate = value;
		// fixed timestep = slow motion if the PC can't hold the fps, set here since FlxG.reset() turns it back on -JloorDev
		FlxG.fixedTimestep = false;
	}

	public static function resizeGame() {
		FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode();
	}

	public static function setFullscreen(value:Bool) {
		openfl.Lib.application.window.fullscreen = value;
		core.api.AppUtil.resizeGame();
	}
}

package core.api;

#if windows
import winapi.WindowsAPI;
#end
import flixel.system.scaleModes.RatioScaleMode;

class WindowAPI {
	public static function init() {
		#if windows
		WindowsAPI.reDefineMainWindowTitle(lime.app.Application.current.window.title);
		WindowsAPI.windowDarkMode(true);
		WindowsAPI.setProgramDPIAware();
		#end
	}

	public static function resizeGame() {
		FlxG.scaleMode = new RatioScaleMode();
	}
}

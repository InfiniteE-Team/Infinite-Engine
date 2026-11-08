package core.api;

#if windows
import winapi.WindowsAPI;
#end
import openfl.Lib;
import sys.io.Process;
import flash.system.System;

class DesktopAPI {
	public static function init() {
		#if windows
		WindowsAPI.reDefineMainWindowTitle(lime.app.Application.current.window.title);
		WindowsAPI.setWindowRound(WindowRound.DWMWCP_ROUND);
		WindowsAPI.windowDarkMode(true);
		#end
		scaleWindow();
	}

	public static function scaleWindow() {
		#if windows
		WindowsAPI.setProgramDPIAware();
		#end
		Lib.application.window.x = Std.int((Lib.application.window.display.bounds.width - Lib.application.window.width) / 2);
		Lib.application.window.y = Std.int((Lib.application.window.display.bounds.height - Lib.application.window.height) / 2);
	}

	public static function setFullscreen(value:Bool) {
		openfl.Lib.application.window.fullscreen = value;
		core.api.AppUtil.resizeGame();
	}

	public static function setBorderless(value:Bool) {
		openfl.Lib.application.window.borderless = value;
	}

	public static function configWindow() {
		switch (SaveData.data.windowmode) {
			case 'Fullscreen':
				core.api.DesktopAPI.setFullscreen(true);
				core.api.DesktopAPI.setBorderless(false);
			case 'Windowed':
				core.api.DesktopAPI.setFullscreen(false);
				core.api.DesktopAPI.setBorderless(false);
			case 'Borderless':
				core.api.DesktopAPI.setFullscreen(false);
				core.api.DesktopAPI.setBorderless(true);
		}
	}
}

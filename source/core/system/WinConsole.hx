package core.system;

#if (cpp && windows && DEBUG_CONSOLE)
import cpp.Lib;

@:cppFileCode('
#include <windows.h>
#include <cstdio>
')
class WinConsole {
	static var isOpen:Bool = false;

	public static function open():Void {
		if (isOpen)
			return;

		var ok:Bool = untyped __cpp__('AllocConsole()');
		if (!ok) {
			isOpen = true;
			return;
		}

		untyped __cpp__('
			FILE* fp;
			freopen_s(&fp, "CONOUT$", "w", stdout);
			freopen_s(&fp, "CONOUT$", "w", stderr);
			freopen_s(&fp, "CONIN$", "r", stdin);
		');

		isOpen = true;
		// Sys.println("Console Open yep");
	}

	public static function close():Void {
		if (!isOpen)
			return;

		untyped __cpp__('FreeConsole()');
		isOpen = false;
	}

	public static function toggle():Void {
		if (isOpen)
			close();
		else
			open();
	}

	public static var opened(get, never):Bool;

	static function get_opened():Bool
		return isOpen;
}
#else
class WinConsole {
	public static function open():Void {}

	public static function close():Void {}

	public static function toggle():Void {}

	public static var opened(get, never):Bool;

	static function get_opened():Bool
		return false;
}
#end

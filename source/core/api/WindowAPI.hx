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

	@:access(flixel.FlxG)
	public static function resizeGame(width:Int, height:Int, ?centerWindow:Bool = true) {
        final prevFullScreen:Bool = FlxG.fullscreen;
        
        FlxG.initialWidth = width;
        FlxG.initialHeight = height;
        FlxG.resizeGame(width, height);
        
        var display = lime.system.System.getDisplay(0);
        var screenWidth:Int = (display != null && display.currentMode != null) ? display.currentMode.width : 1920;
        var screenHeight:Int = (display != null && display.currentMode != null) ? display.currentMode.height : 1080;
        
        var windowWidth:Int = width;
        var windowHeight:Int = height;
        
        if (screenWidth < width || screenHeight < height) {
            var scaleX:Float = screenWidth / width;
            var scaleY:Float = screenHeight / height;
            var minScale:Float = Math.min(scaleX, scaleY) * 0.85; 
            
            windowWidth = Math.floor(width * minScale);
            windowHeight = Math.floor(height * minScale);
        }
        
        FlxG.resizeWindow(windowWidth, windowHeight);
        
        #if !mobile
        if (centerWindow) {
            openfl.Lib.application.window.x = Std.int((screenWidth - windowWidth) / 2);
            openfl.Lib.application.window.y = Std.int((screenHeight - windowHeight) / 2);
        }
        #end
        
        for (cam in FlxG.cameras.list) {
            cam.width = width;
            cam.height = height;
        }
        
        FlxG.scaleMode = new RatioScaleMode(false);
        
        #if !mobile
        FlxG.fullscreen = prevFullScreen;
        #end
    }
}

package;

import core.EngineData;
import core.ui.FPSCounter;
import openfl.display.Sprite;
// crash handler
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
import core.system.warnings.TroubleShooter;

class Main extends Sprite {
	public var fps:FPSCounter = new FPSCounter(5, 5, 0xFFFFFF);

	public function new() {
		super();
		mainGame();

		stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, onKeyDown);
		#if CRASH_HANDLER
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrashHandler);
		#end
	}

	function mainGame() {
		addChild(new core.Game(core.ConfigMain));
		addChild(fps);
	}

	private function onKeyDown(e:openfl.events.KeyboardEvent):Void {
		if (e.keyCode == flash.ui.Keyboard.F11) {
			openfl.Lib.application.window.fullscreen = !openfl.Lib.application.window.fullscreen;
			core.api.WindowAPI.resizeGame();
		}

		#if DEBUG_CONSOLE
		if (e.keyCode == flash.ui.Keyboard.F2) {
			core.system.WinConsole.toggle();
		}
		#end
	}

	#if CRASH_HANDLER
	private function onCrashHandler(event:UncaughtErrorEvent):Void {
		event.preventDefault();

		var erroryep = CallStack.exceptionStack(true);
		var details:String = CallStack.toString(erroryep);

		var crash:String = Std.string(event.error) + "\n" + details;

		var crashHandler = new core.system.warnings.TroubleShooter();
		crashHandler.launchCrash(crash);
	}
	#end
}

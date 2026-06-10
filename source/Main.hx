package;

import core.system.FPSCounter;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.events.Event;
import flixel.FlxState;
import core.config.Controls;
import core.config.SaveData;
import lime.app.Application;
import core.json.engine.GlobalData.GlobalConfig;
import core.scripting.ScriptGlobals;
import core.config.CursorConfig;
//
#if windows
import winapi.WindowsAPI;
#end

class Main extends Sprite {
	public var fps:FPSCounter = new FPSCounter(5, 5, 0xFFFFFF);
	public var mainState:Class<FlxState> = game.PlayState;

	public static var save:SaveData;
	public static var controls:Controls;
	public static var globalData:GlobalConfig = new GlobalConfig();
	public static var cursor:CursorConfig;

	public var framerate:Int = 60;

	public function new() {
		super();
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	private function added(?e:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, added);

		stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, onKeyDown);

		mainGame();
	}

	function mainGame() {
		configGame();
		addChild(new FlxGame(1280, 720, mainState, framerate, framerate, true, false));
		addChild(fps);
		cursor = new CursorConfig();
		cursor.loadCursor();

		if (globalData.developerMode)
			Trace.init();

		#if windows
		WindowsAPI.reDefineMainWindowTitle(lime.app.Application.current.window.title);
		WindowsAPI.windowDarkMode(true);
		#end
	}

	function configGame() {
		FlxG.save.bind("InfiniteEngine","InfiniteTeam");
		
		SaveData.init();
		SaveData.initSave();

		controls = new Controls();

		globalData.configGlobal();

		if (globalData.startState != null)
			mainState = globalData.startState;

		framerate = SaveData.data.framerate;

		#if (DISCORD_ALLOWED && hxdiscord_rpc < "1.2.0")
		core.api.DiscordAPI.init();
		Application.current.onExit.add(function(exitCode:Int) {
			core.api.DiscordAPI.shutdown();
		});
		#end

		#if HSCRIPT_ALLOWED
		ScriptGlobals.init();
		#end
	}

	private function onKeyDown(e:openfl.events.KeyboardEvent):Void {
		if (e.keyCode == flash.ui.Keyboard.F11) {
			FlxG.fullscreen = !FlxG.fullscreen;
		}
	}
}

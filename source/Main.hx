package;

import core.system.FPSCounter;
import core.system.WindowConfig;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageDisplayState;
import openfl.Lib;
import flixel.FlxState;
import game.PlayState;
import core.config.Controls;
import core.config.SaveData;
import lime.app.Application;
import core.json.engine.GlobalData.GlobalConfig;
import core.scripting.ScriptGlobals;
import core.config.CursorConfig;

class Main extends Sprite {
	public var fps:FPSCounter = new FPSCounter(5, 5, 0xFFFFFF);
	public var mainState:Class<FlxState> = PlayState;

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
		mainGame();
	}

	function mainGame() {
		configGame();
		addChild(new FlxGame(1280, 720, mainState, framerate, framerate, true, false));
		addChild(fps);
		cursor = new CursorConfig();
		cursor.loadCursor();

		WindowConfig.applyAccentColor();
	}

	function configGame() {
		save = new SaveData();
		save.loadConfig();
		controls = new Controls(save);
		globalData.configGlobal();

		if (globalData.startState != null)
			mainState = globalData.startState;

		framerate = save.framerate;
		
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

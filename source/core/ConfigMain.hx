package core;

import core.config.CursorConfig;
import core.json.engine.GlobalData.GlobalConfig;
import core.config.Controls;
import core.config.SaveData;
import windowmodcharting.engineImplementation.ConductorImplementation;
import core.scripting.ScriptGlobals;
//
#if windows
import winapi.WindowsAPI;
#end

class ConfigMain extends flixel.FlxState {
	public var mainState:Class<MusicBeatState> = game.PlayState;

	public static var globalData:GlobalConfig = new GlobalConfig();

	public static var save:SaveData;
	public static var controls:Controls;

	public static var cursor:CursorConfig;

	public function new() {
		super();
	}

	override public function create() {
		FlxG.save.bind("InfiniteEngine", "InfiniteTeam");

		SaveData.init();
		SaveData.initSave();

		controls = new Controls();

		globalData.configGlobal();

		if (globalData.startState != null)
			mainState = globalData.startState;

		InfiniteUtil.updateFramerate();

		#if (DISCORD_ALLOWED && hxdiscord_rpc < "1.2.0")
		core.api.DiscordAPI.init();
		Application.current.onExit.add(function(exitCode:Int) {
			core.api.DiscordAPI.shutdown();
		});
		#end

		#if HSCRIPT_ALLOWED
		ScriptGlobals.init();
		#end

		cursor = new CursorConfig();
		cursor.loadCursor();

		#if windows
		WindowsAPI.reDefineMainWindowTitle(lime.app.Application.current.window.title);
		WindowsAPI.windowDarkMode(true);
		#end

		ConductorImplementation.custom_songPosition = () -> core.rhythm.RhythmCore.songPosition;
		ConductorImplementation.custom_crochet = () -> core.rhythm.RhythmCore.crochet;

		if (globalData.developerMode)
			Trace.init();

		MusicBeatState.switchState(Type.createInstance(mainState, []));
	}
}

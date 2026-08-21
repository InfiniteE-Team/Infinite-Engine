package core;

import core.config.CursorConfig;
import core.json.engine.GlobalData.GlobalConfig;
import modding.scripting.ScriptGlobals;

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
		SaveData.initSave();

		controls = new Controls();

		Controls.init();

		FlxG.mouse.visible = false;

		Paths.clearCache();
		core.assets.Library.reloadMods();

		modding.mods.ModData.ModConfig.init();

		globalData.configGlobal();

		if (globalData.developerMode)
			Trace.init();

		if (globalData.startState != null)
			mainState = globalData.startState;

		InfiniteUtil.updateFramerate();

		core.config.SaveScore.load();

		core.ui.FPSCounter.instance.updateVisibility();

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

		flixel.FlxSprite.defaultAntialiasing = true;

		FlxG.autoPause = false;

		/*
			ConductorImplementation.custom_songPosition = () -> core.rhythm.RhythmCore.songPosition;
			ConductorImplementation.custom_crochet = () -> core.rhythm.RhythmCore.crochet; */

		if (globalData.startStateScript != null) {
			modding.scripting.types.ScriptClass.switchState(globalData.startStateScript);
		} else {
			MusicBeatState.switchState(() -> Type.createInstance(mainState, []));
		}
	}
}

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

		#if DISCORD_ALLOWED
		var discordId = (modding.mods.ModData.ModConfig.modData?.discord != null
			&& modding.mods.ModData.ModConfig.modData.discord != "") ? modding.mods.ModData.ModConfig.modData.discord : "1534274562496270356";
		core.api.DiscordAPI.initWithId(discordId);
		core.api.DiscordAPI.instance.setPresence({
			state: "In the Menu",
			details: "Infinite Engine",
			largeImageKey: "icon"
		});
		lime.app.Application.current.onExit.add(function(exitCode:Int) {
			core.api.DiscordAPI.instance.shutdown();
		});
		#end

		#if HSCRIPT_ALLOWED
		ScriptGlobals.init();
		#end

		cursor = new CursorConfig();
		cursor.loadCursor();

		flixel.FlxSprite.defaultAntialiasing = true;

		FlxG.autoPause = false;

		var innerState:() -> MusicBeatState = if (globalData.startStateScript != null) () ->
			modding.scripting.types.ScriptClass.load(globalData.startStateScript); else() -> Type.createInstance(mainState, []);

		MusicBeatState.switchState(() -> new states.preload.FunkinPreloader(innerState));
	}
}

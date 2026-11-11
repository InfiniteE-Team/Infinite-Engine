package core;

import core.config.CursorConfig;
import core.json.engine.GlobalData.GlobalConfig;
import modding.scripting.ScriptGlobals;

class ConfigMain extends flixel.FlxState {
	var mainState:String = null;

	public static var globalData:GlobalConfig = new GlobalConfig();

	public static var save:SaveData;
	public static var controls:Controls;

	public static var cursor:CursorConfig;

	public function new() {
		super();
	}

	override public function create() {
		SaveData.initSave();

		#if desktop
		core.api.DesktopAPI.configWindow();
		#end

		controls = new Controls();

		Controls.init();

		FlxG.mouse.visible = false;

		#if android
		if (!extension.androidtools.Permissions.hasPermission('android.permission.MANAGE_EXTERNAL_STORAGE'))
			extension.androidtools.Permissions.requestPermission('android.permission.MANAGE_EXTERNAL_STORAGE');
		#end

		core.assets.Library.initPaths();
		Paths.clearCache();
		core.assets.Library.reloadMods();

		modding.mods.ModData.ModConfig.init();

		globalData.configGlobal();

		if (globalData.developerMode)
			Console.init();

		if (globalData.startState != null)
			mainState = globalData.startState;

		core.api.AppUtil.updateFramerate(SaveData.data.framerate);

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
		lime.app.Application.current.onExit.add(function(exitCode) {
			core.api.DiscordAPI.instance.shutdown();
		});
		#end

		#if HSCRIPT_ALLOWED
		ScriptGlobals.init();
		globalData.loadGlobalScripts();
		GlobalConfig.globalScripts.executeAll();
		GlobalConfig.globalScripts.call('onInit', []);
		#end

		cursor = new CursorConfig();
		cursor.loadCursor();

		flixel.FlxSprite.defaultAntialiasing = true;

		FlxG.autoPause = false;

		if (mainState != null) {
			var innerState:() -> MusicBeatState = () -> {
				var cls = Type.resolveClass(mainState);
				if (cls != null)
					return Type.createInstance(cls, []);
				else
					return modding.scripting.types.ScriptClass.load(mainState);
			};
			MusicBeatState.switchState(() -> new states.preload.FunkinPreloader(innerState));
		}
	}
}

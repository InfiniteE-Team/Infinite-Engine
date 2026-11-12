package modding.mods;

import sys.FileSystem;
import lime.app.Application;
import lime.graphics.Image;
import states.menus.ModsState;

typedef ModData = {
	var ?name:String;
	var ?title:String;
	var ?author:String;
	var ?appIcon:String;
	var ?description:String;
	var ?startingMod:Bool;

	// APIs
	var ?mod_version:String;
	var ?api_version:String;

	var ?discord:String;
	var ?webPage:String;
}

class ModConfig {
	public static var modData:ModData;

	public static var title(get, never):String;
	public static var apiMods(get, never):String;
	public static var appIconPath(get, never):String;

	public function new() {}

	public static function init() {
		var jsonPath = core.assets.Library.findLib('meta.json') ?? core.assets.Library.findLib('_polymod_meta.json');

		if (jsonPath == null || !FileSystem.exists(jsonPath)) {
			trace('No meta.json found, using the engine defaults.');
			modData = null;
		} else {
			try {
				modData = FormatJson.readJson(jsonPath);
			} catch (e:Dynamic) {
				Console.log('Error to parsed the mod: $e');
				modData = null;
			}
		}

		lime.app.Application.current.window.title = title;
		updateAppIcon();
	}

	private static function get_title():String {
		if (modData == null || modData.title == null) {
			return core.system.EngineData.title;
		}
		return modData.title;
	}

	private static function get_apiMods():String {
		if (modData == null)
			return "";
		return modData.api_version ?? "0.1.0";
	}

	private static function get_appIconPath():String {
		if (modData != null && modData.appIcon != null && modData.appIcon != "") {
			var modIcon = Paths.getPath(modData.appIcon + '.png');
			if (FileSystem.exists(modIcon)) {
				return modIcon;
			}
		}
		return Paths.getPath(core.system.EngineData.DEFAULT_ICON + '.png');
	}

	public static function loadForMod(modName:String):ModData {
		var modPath = '${core.assets.Library.modsFolder}/$modName/meta.json';
		// V-Slice mods ship Polymod's meta instead -JloorDev
		if (!sys.FileSystem.exists(modPath))
			modPath = '${core.assets.Library.modsFolder}/$modName/_polymod_meta.json';
		if (!sys.FileSystem.exists(modPath))
			return null;
		try {
			return FormatJson.readJson(modPath);
		} catch (e:Dynamic) {
			Console.log('Error parsing meta for mod $modName: $e');
			return null;
		}
	}

	public static function updateAppIcon():Void {
		setAppIcon(appIconPath);
	}

	public static function setAppIcon(iconPath:String):Void {
		#if desktop
		if (!FileSystem.exists(iconPath)) {
			Console.log('The archive png not existed: $iconPath', true);
			return;
		}

		try {
			var iconImage:Image = Image.fromFile(iconPath);
			if (iconImage != null && Application.current != null && Application.current.window != null) {
				Application.current.window.setIcon(iconImage);
			}
		} catch (e:Dynamic) {
			Console.log('Error to apply the icon: $e', true);
		}
		#end
	}
}

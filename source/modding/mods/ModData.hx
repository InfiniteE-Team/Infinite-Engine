package modding.mods;

import sys.FileSystem;
import lime.app.Application;
import lime.graphics.Image;
import states.menus.ModsState;

typedef ModData = {
	var ?nameMod:String;
	var ?author:String;
	var ?appIcon:String;
	var ?description:String;
	var ?startingMod:Bool;

	// APIs
	var ?discord:String;
	var ?webPage:String;
}

class ModConfig {
	public static var modData:ModData;
	
	public function new() {}

	public static function init() {
		var jsonPath = Paths.getPath('meta', 'json');
		if (jsonPath == null || !FileSystem.exists(jsonPath)) {
			Trace.traceOnce('The mod file "meta.json" was not found in: $jsonPath', true);
			return;
		}

		try {
			modData = FormatJson.readJson(jsonPath);
			if (modData.appIcon != null && modData.appIcon != "") {
				setAppIcon(modData.appIcon);
			}
		} catch (e:Dynamic) {
			Trace.traceOnce('Error to parsed the mod: $e');
		}
	}

	public static function setAppIcon(iconPath:String):Void {
		#if desktop
		if (!FileSystem.exists(iconPath)) {
			Trace.traceOnce('The archive png not existed: $iconPath', true);
			return;
		}

		try {
			var iconImage:Image = Image.fromFile(iconPath);

			if (iconImage != null && Application.current != null && Application.current.window != null) {
				Application.current.window.setIcon(iconImage);
			}
		} catch (e:Dynamic) {
			Trace.traceOnce('Error to apply the icon: $e', true);
		}
		#end
	}
}

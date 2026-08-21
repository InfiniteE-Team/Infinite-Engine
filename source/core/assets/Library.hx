package core.assets;

import sys.FileSystem;
import modding.mods.ModsRegistry;

class Library {
	public static var baseFolder:String = "assets";
	public static var modsFolder:String = "mods";

	public function new() {}

	public static function getAvailableMods():Array<String> {
		var modNames:Array<String> = [];

		if (!FileSystem.exists(modsFolder)) {
			try FileSystem.createDirectory(modsFolder) catch (e:Dynamic) {}
		}

		if (FileSystem.exists(modsFolder) && FileSystem.isDirectory(modsFolder)) {
			for (item in FileSystem.readDirectory(modsFolder)) {
				var fullPath = '$modsFolder/$item';
				if (FileSystem.isDirectory(fullPath)) {
					modNames.push(item);
				}
			}
		}

		return modNames;
	}

	public static function reloadMods():Void {
		@:privateAccess
		Paths.pathCache.clear();
		ModsRegistry.mods = getAvailableMods();

		Trace.traceOnce('Mods scan → cwd: ${Sys.getCwd()} | found: ${ModsRegistry.mods}');

		var savedMod = SaveData.data.currentMod;
		var savedOnMod = SaveData.data.onMod;

		if (savedMod != null && savedMod != '' && ModsRegistry.mods.contains(savedMod)) {
			ModsRegistry.currentMod = savedMod;
			ModsRegistry.onMod = savedOnMod != null ? savedOnMod : true;
		} else {
			ModsRegistry.onMod = (ModsRegistry.mods.length > 0);
			ModsRegistry.currentMod = ModsRegistry.mods.length > 0 ? ModsRegistry.mods[0] : '';
		}
	}

	public static function findLib(file:String):String {
		@:privateAccess
		if (Paths.pathCache.exists(file))
			return Paths.pathCache.get(file);

		if (ModsRegistry.onMod) {
			if (ModsRegistry.currentMod != null && ModsRegistry.currentMod != '') {
				var currentModPath = '$modsFolder/${ModsRegistry.currentMod}/$file';
				if (FileSystem.exists(currentModPath)) {
					@:privateAccess
					Paths.pathCache.set(file, currentModPath);
					return currentModPath;
				}
			}

			for (mod in ModsRegistry.mods) {
				if (mod == ModsRegistry.currentMod)
					continue;

				var modPath = '$modsFolder/$mod/$file';
				if (FileSystem.exists(modPath)) {
					@:privateAccess
					Paths.pathCache.set(file, modPath);
					return modPath;
				}
			}
		}

		var basePath = '$baseFolder/$file';
		if (FileSystem.exists(basePath)) {
			@:privateAccess
			Paths.pathCache.set(file, basePath);
			return basePath;
		}

		return null;
	}
}

package core.assets;

import sys.FileSystem;
import modding.mods.ModsRegistry;

class Library {
	public static var baseFolder:String = "assets";
	public static var modsFolder:String = "mods";

	public function new() {}

	public static function getAvailableMods():Array<String> {
		var modNames:Array<String> = [];

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
		ModsRegistry.mods = getAvailableMods();

		if (SaveData.data.currentMod != null && ModsRegistry.mods.contains(SaveData.data.currentMod)) {
			ModsRegistry.currentMod = SaveData.data.currentMod;
			ModsRegistry.onMod = SaveData.data.onMod != null ? SaveData.data.onMod : true;
		} else {
			ModsRegistry.onMod = (ModsRegistry.mods.length > 0);
			if (ModsRegistry.mods.length > 0)
				ModsRegistry.currentMod = ModsRegistry.mods[0];
			else
				ModsRegistry.currentMod = '';
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

	public static function listFolder(folder:String):Array<String> {
		var result:Array<String> = [];

		var addFilesFromDir = function(dirPath:String) {
			if (FileSystem.exists(dirPath)) {
				for (name in FileSystem.readDirectory(dirPath)) {
					if (!result.contains(name)) {
						result.push(name);
					}
				}
			}
		};

		if (ModsRegistry.onMod) {
			if (ModsRegistry.currentMod != null && ModsRegistry.currentMod != '') {
				addFilesFromDir('$modsFolder/${ModsRegistry.currentMod}/$folder');
			}

			for (mod in ModsRegistry.mods) {
				if (mod != ModsRegistry.currentMod) {
					addFilesFromDir('$modsFolder/$mod/$folder');
				}
			}
		}

		addFilesFromDir('$baseFolder/$folder');

		return result;
	}
}

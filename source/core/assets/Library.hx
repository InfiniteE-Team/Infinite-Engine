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
			try
				FileSystem.createDirectory(modsFolder)
			catch (e:Dynamic) {}
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
		clearModCache();
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
		if (Paths.pathCache.exists(file)) {
			return Paths.pathCache.get(file);
		}

		if (ModsRegistry.onMod) {
			if (ModsRegistry.currentMod != null && ModsRegistry.currentMod != '') {
				var currentModPath = '$modsFolder/${ModsRegistry.currentMod}/$file';
				if (FileSystem.exists(currentModPath)) {
					@:privateAccess
					Paths.pathCache.set(file, currentModPath);
					return currentModPath;
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

	public static function clearModCache():Void {
		@:privateAccess {
			var pathsToRemove = [
				for (k => v in Paths.pathCache)
					if (v != null && v.startsWith(modsFolder)) k
			];
			for (trash in pathsToRemove)
				Paths.pathCache.remove(trash);

			var assetsToRemove = [
				for (k in Paths.cache.keys())
					if (k.startsWith(modsFolder)) k
			];
			for (trashes in assetsToRemove) {
				var asset = Paths.cache.get(trashes);
				if (asset is flixel.graphics.frames.FlxFramesCollection) {
					var fc = cast(asset, flixel.graphics.frames.FlxFramesCollection);
					fc.parent?.bitmap?.dispose();
					if (fc.parent != null)
						FlxG.bitmap.remove(fc.parent);
					fc.destroy();
				} else if (asset is flixel.graphics.FlxGraphic) {
					var graphic = cast(asset, flixel.graphics.FlxGraphic);
					graphic.bitmap?.dispose();
					FlxG.bitmap.remove(graphic);
					graphic.destroy();
				}
				Paths.cache.remove(trashes);
			}
		}

		core.rhythm.audio.Sound.clearGlobalCache();
	}
}

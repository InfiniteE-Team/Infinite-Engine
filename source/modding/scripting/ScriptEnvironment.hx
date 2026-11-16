package modding.scripting;

import hxscript.Environment;
import hxscript.Module;

class ScriptEnvironment extends Environment {
	public var scriptFolders:Array<String> = [];

	override public function resolve(path:String):hxscript.types.IScriptedType {
		var found = super.resolve(path);
		if (found != null)
			return found;

		var filePath = importPathToFile(path);
		if (filePath != null && sys.FileSystem.exists(filePath)) {
			ScriptHandler.loadModuleFile(filePath, path);
			return super.resolve(path);
		}

		return null;
	}

	public function importPathToFile(importPath:String):Null<String> {
		var reload = importPath.replace('.', '/') + '.hx';

		var mod = modding.mods.ModsRegistry.currentMod;
		if (mod != null && mod != '') {
			var path = '${core.assets.Library.modsFolder}/$mod/$reload';
			if (sys.FileSystem.exists(path))
				return path;
		}

		for (folder in scriptFolders) {
			var path = '$folder/$reload';
			if (sys.FileSystem.exists(path))
				return path;
		}

		return null;
	}
}

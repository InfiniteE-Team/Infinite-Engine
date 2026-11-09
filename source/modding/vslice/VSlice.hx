package modding.vslice;

import sys.FileSystem;
import core.assets.Library;
import modding.mods.ModsRegistry;

// shared bits of the V-Slice (Polymod) port: detection and json helpers, the rest lives next to this file -JloorDev
class VSlice {
	static var _checkedMod:String = null;
	static var _active:Bool = false;

	public static function isActive():Bool {
		if (!ModsRegistry.onMod || ModsRegistry.currentMod == null || ModsRegistry.currentMod == '')
			return false;
		if (_checkedMod != ModsRegistry.currentMod) {
			_checkedMod = ModsRegistry.currentMod;
			_active = FileSystem.exists('${modRoot()}/_polymod_meta.json');
		}
		return _active;
	}

	public static function modRoot():String
		return '${Library.modsFolder}/${ModsRegistry.currentMod}';

	public static function readMod(rel:String):Dynamic {
		var path = '${modRoot()}/$rel';
		return FileSystem.exists(path) ? FormatJson.readJson(path) : null;
	}

	// Polymod's _merge: JSON Patch ops a mod applies to a base game file -JloorDev
	public static function applyMerge(rel:String, data:Dynamic):Dynamic {
		var ops:Array<Dynamic> = isActive() ? readMod('_merge/$rel') : null;
		if (ops == null || data == null)
			return data;
		for (op in ops) {
			var parts = Std.string(op.path).split('/').slice(1);
			if (parts.length == 0)
				continue;
			var parent:Dynamic = data;
			for (i in 0...parts.length - 1)
				parent = Std.isOfType(parent, Array) ? parent[Std.parseInt(parts[i])] : Reflect.field(parent, parts[i]);
			if (parent == null)
				continue;
			var key = parts[parts.length - 1];
			if (Std.isOfType(parent, Array)) {
				var list:Array<Dynamic> = parent;
				var at = key == '-' ? list.length : Std.parseInt(key);
				switch (op.op) {
					case 'add':
						list.insert(at, op.value);
					case 'replace':
						list[at] = op.value;
					case 'remove':
						list.splice(at, 1);
				}
			} else
				switch (op.op) {
					case 'add' | 'replace':
						Reflect.setField(parent, key, op.value);
					case 'remove':
						Reflect.deleteField(parent, key);
				}
		}
		return data;
	}

	public static function sortedJson(rel:String):Array<String> {
		var dir = '${modRoot()}/$rel';
		if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir))
			return [];
		var files = [for (f in FileSystem.readDirectory(dir)) if (StringTools.endsWith(f, '.json')) f];
		files.sort(Reflect.compare);
		return files;
	}

	public static function stripLibrary(path:String):String {
		var colon = path.indexOf(':');
		return colon >= 0 ? path.substr(colon + 1) : path;
	}

	public static function num(arr:Dynamic, i:Int):Float {
		var v:Dynamic = arr != null ? arr[i] : null;
		return v != null ? v : 0.0;
	}

	public static function pair(v:Dynamic, fallback:Float):Array<Float> {
		if (v == null)
			return [fallback, fallback];
		if (Std.isOfType(v, Array))
			return [num(v, 0), num(v, 1)];
		var f:Float = v;
		return [f, f];
	}
}

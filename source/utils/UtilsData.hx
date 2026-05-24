package utils;
import sys.FileSystem;
import core.json.JsonWatcher;

class UtilsData {
	public static function readJson<T>(data:String, ?callback:Void->Void):Null<T> {
		if (data == null || !sys.FileSystem.exists(data))
			return null;

		#if HSCRIPT_ALLOWED
		if (Main.globalData.developerMode)
			JsonWatcher.watch(data, callback);
		#end

		return cast haxe.Json.parse(sys.io.File.getContent(data));
	}
}

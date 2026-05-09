package utils;

import sys.FileSystem;

class UtilsData
{
    public static function readJson<T>(data:String):Null<T>{
		if (!sys.FileSystem.exists(data))
			return null;
        return cast haxe.Json.parse(sys.io.File.getContent(data));
    }
}
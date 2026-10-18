package funkin;

// V-Slice FunkinMemory for scripts: preloading hints, the engine loads on use -JloorDev
@:keep
class FunkinMemory {
	public static function cacheTexture(key:String):Void {}

	public static function permanentCacheTexture(key:String):Void {}

	public static function cacheSound(key:String):Void {}

	public static function permanentCacheSound(key:String):Void {}

	public static function purgeCache(?callGarbageCollector:Bool):Void {}
}

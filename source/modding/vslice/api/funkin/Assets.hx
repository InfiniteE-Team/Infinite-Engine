package funkin;

// Assets Text for Shaders in V-Slice
@:keep
class Assets {
    public static function getText(id:String):String {
        if (sys.FileSystem.exists(id))
            return sys.io.File.getContent(id);
        return openfl.utils.Assets.getText(id);
    }

    public static function exists(id:String, ?type:openfl.utils.AssetType):Bool
        return sys.FileSystem.exists(id) || openfl.utils.Assets.exists(id, type);

    public static function getBitmapData(id:String, useCache:Bool = true):openfl.display.BitmapData
        return openfl.utils.Assets.getBitmapData(id, useCache);

    public static function getSound(id:String, useCache:Bool = true):openfl.media.Sound
        return openfl.utils.Assets.getSound(id, useCache);

    public static function getBytes(id:String):haxe.io.Bytes
        return openfl.utils.Assets.getBytes(id);

    public static function list(?type:openfl.utils.AssetType):Array<String>
        return openfl.utils.Assets.list(type);

    public static function isLocal(id:String, ?type:openfl.utils.AssetType, useCache:Bool = true):Bool
        return sys.FileSystem.exists(id) || openfl.utils.Assets.isLocal(id, type, useCache);
}
package funkin;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

// V-Slice's Paths for .hxc scripts, resolved through the engine's mod-aware paths -JloorDev
@:keep
class Paths {
	public static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames {
		var frames:Dynamic = core.assets.Paths.getAnimated(key);
		return Std.isOfType(frames, FlxAtlasFrames) ? frames : null;
	}

	public static function image(key:String, ?library:String):FlxGraphic {
		var path:String = core.assets.Paths.getPath(key, 'image');
		if (path == null)
			return null;
		var graphic = FlxG.bitmap.get(path);
		return graphic ?? FlxGraphic.fromBitmapData(openfl.display.BitmapData.fromFile(path), false, path);
	}

	public static function sound(key:String, ?library:String):Dynamic
		return fileSound(core.assets.Paths.getPath(key, 'sound'));

	public static function music(key:String, ?library:String):Dynamic
		return fileSound(core.assets.Paths.getPath(key, 'music'));

	public static function font(key:String):String
		return core.assets.Library.findLib('fonts/$key') ?? key;

	public static function animateAtlas(key:String, ?library:String):Null<String> {
		var json = core.assets.Library.findLib('images/$key/Animation.json');
		return json != null ? haxe.io.Path.directory(json) : null;
	}

	public static function videos(key:String, ?library:String):String {
		var path = core.assets.Library.findLib('videos/videos/$key.mp4') ?? core.assets.Library.findLib('videos/$key.mp4');
		return path != null ? sys.FileSystem.fullPath(path) : 'videos/$key.mp4';
	}

	static function fileSound(path:String):Dynamic {
		if (path == null || openfl.utils.Assets.exists(path))
			return path;
		var loaded = openfl.media.Sound.fromFile(path);
		return loaded != null ? loaded : path;
	}

	public static function frag(key:String):String
		return core.assets.Paths.getPath(key, 'shaders') ?? '';
}

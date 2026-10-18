package funkin.audio;

import flixel.FlxG;
import flixel.sound.FlxSound;

// V-Slice FunkinSound for scripts: load/playOnce giving a plain FlxSound, reading mod files directly
// shortcut: not a FlxSound subclass (FlxSound has its own load), so `:FunkinSound` in scripts is read as Dynamic -JloorDev
@:keep
class FunkinSound {
	public static function load(path:String, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false, autoPlay:Bool = false, ?persist:Bool,
			?onComplete:Void->Void, ?onLoad:Void->Void):Null<FlxSound> {
		var asset = soundAsset(path);
		var sound = new FlxSound();
		if (asset != null)
			sound.loadEmbedded(asset, looped, autoDestroy, onComplete);
		sound.volume = volume;
		FlxG.sound.list.add(sound);
		if (onLoad != null)
			onLoad();
		if (autoPlay)
			sound.play();
		return sound;
	}

	public static function playOnce(path:String, volume:Float = 1.0, ?onComplete:Void->Void, ?onLoad:Void->Void):Null<FlxSound>
		return load(path, volume, false, true, true, false, onComplete, onLoad);

	static function soundAsset(path:Dynamic):Dynamic {
		if (path == null || !Std.isOfType(path, String))
			return path;
		var p:String = path;
		if (openfl.utils.Assets.exists(p))
			return p;
		var file = sys.FileSystem.exists(p) ? p : core.assets.Library.findLib(p);
		return file != null ? openfl.media.Sound.fromFile(file) : null;
	}
}

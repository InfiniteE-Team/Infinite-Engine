package core.assets;

import animate.FlxAnimateFrames;
import sys.FileSystem;
import game.PlayState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;

class Paths {
	static final libs = ["engine", "assets"];
	private static var cache = new Map<String, Dynamic>();

	public static function getPath(fileName:String, ?type:String = "default"):Dynamic {
		try {
			switch (type) {
				case "data":
					return findLib("data/" + fileName);
				case "json":
					return findLib(fileName + '.json');
				case "font":
					return findLib("fonts/" + fileName);
				case "image":
					return findLib("images/" + fileName + '.png');
				case "sound":
					return findLib("sounds/" + fileName + '.ogg');
				case "music":
					return findLib("music/" + fileName + '.ogg');
				case "songAudio":
					return findLib('songs/${PlayState.SONG.songName.toLowerCase()}/audio/$fileName.ogg');
				case "animated":
					return getAnimated(fileName);
				case "xml":
					return findLib(fileName + '.xml');
				case "songScript":
					return findLib('songs/${PlayState.SONG.songName.toLowerCase()}/scripts/$fileName.hx');
				case "frag":
					return findLib('shaders/$fileName.frag');
				// scripting
				case "states":
					return findLib('states/' + fileName + '.hx');
				case "script":
					return findLib('scripts/$fileName.hx');
				default:
					return findLib(fileName);
			}
		} catch (e:Dynamic) {
			Trace.traceOnce('Paths: "$fileName" not found: $e');
			return null;
		}
	}

	public static function findLib(file:String):String {
		for (lib in libs)
			if (FileSystem.exists('$lib/$file'))
				return '$lib/$file';
		return null;
	}

	public static function listFolder(folder:String):Array<String> {
		var result = [];
		for (lib in libs) {
			if (FileSystem.exists('$lib/$folder')) {
				for (name in FileSystem.readDirectory('$lib/$folder'))
					if (!result.contains(name))
						result.push(name);
			}
		}
		return result;
	}

	public static function getAnimated(fileName:String):Dynamic {
		// atlas texture
		if (cache.exists(fileName))
			return cache.get(fileName);

		var result:Dynamic = null;

		var folder = findLib('images/$fileName');
		if (folder != null && FileSystem.exists('$folder/Animation.json'))
			result = FlxAnimateFrames.fromAnimate(folder);

		if (result == null) {
			var xml = findLib('images/$fileName.xml');
			if (xml != null)
				result = FlxAtlasFrames.fromSparrow(getPath(fileName, 'image'), xml);
		}

		if (result == null) {
			var txt = findLib('images/$fileName.txt');
			if (txt != null)
				result = FlxAtlasFrames.fromLibGdx(getPath(fileName, 'image'), txt);
		}

		if (result == null) {
			var json = findLib('images/$fileName.json');
			if (json != null)
				result = FlxAtlasFrames.fromTexturePackerJson(getPath(fileName, 'image'), json);
		}

		if (result == null) {
			var png = findLib('images/$fileName.png');
			if (png != null)
				result = png;
		}

		if (result != null)
			cache.set(fileName, result);

		return result;
	}

	public static function clearCache():Void {
		for (_ => asset in cache) {
			if (asset is FlxFramesCollection) {
				var frames = cast(asset, FlxFramesCollection);
				if (frames.parent != null)
					FlxG.bitmap.remove(frames.parent);
				frames.destroy();
			} else if (asset is flixel.graphics.FlxGraphic) {
				var asset = cast(asset, flixel.graphics.FlxGraphic);
				FlxG.bitmap.remove(asset);
				asset.destroy();
			}
		}
		cache.clear();
		FunkinSprite.cacheOffsets.clear();
	}
}

package core.assets;

import animate.FlxAnimateFrames;
import sys.FileSystem;
import game.PlayState;
import flixel.graphics.frames.FlxAtlasFrames;

class Paths {
	static final libs = ["engine", "assets"];

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
					return FlxAtlasFrames.fromSparrow(getPath(fileName, "image"), getPath("images/" + fileName, "xml"));
				case "xml":
					return findLib(fileName + '.xml');
				case "class":
					return findLib('scripts/states/$fileName.hx');
				case "songScript":
					return findLib('songs/${PlayState.SONG.songName.toLowerCase()}/scripts/$fileName.hx');
				default:
					return findLib(fileName);
			}
		} catch (e:Dynamic) {
			trace('Paths: "$fileName" not found: $e');
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
		var folder = findLib('images/$fileName');
		if (folder != null && FileSystem.exists('$folder/Animation.json'))
			return FlxAnimateFrames.fromAnimate(folder);

		var xml = findLib('images/$fileName.xml');
		if (xml != null)
			return FlxAtlasFrames.fromSparrow(getPath(fileName, 'image'), xml);

		var txt = findLib('images/$fileName.txt');
		if (txt != null)
			return FlxAtlasFrames.fromLibGdx(getPath(fileName, 'image'), txt);

		var json = findLib('images/$fileName.json');
		if (json != null)
			return FlxAtlasFrames.fromTexturePackerJson(getPath(fileName, 'image'), json);

		var png = findLib('images/$fileName.png');
		if (png != null)
			return png;

		return null;
	}
}

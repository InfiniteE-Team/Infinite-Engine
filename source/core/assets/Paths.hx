package core.assets;

import sys.io.File;
import animate.FlxAnimateFrames;
import sys.FileSystem;
import game.PlayState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import sys.thread.Thread;

class Paths {
	static final libs = ["assets", "engine"];
	private static var pathCache = new Map<String, String>();

	private static var cache = new Map<String, Dynamic>();

	public static function getPath(fileName:String, ?type:core.enums.AssetType = DEFAULT):Dynamic {
		try {
			switch (type) {
				case DATA:
					return findLib("data/" + fileName);
				case JSON:
					return findLib(fileName + '.json');
				case FONT:
					return findLib("fonts/" + fileName);
				case IMAGE:
					return findLib("images/" + fileName + '.png');
				case SOUND:
					return findLib("sounds/" + fileName + '.ogg');
				case MUSIC:
					return findLib("music/" + fileName + '.ogg');
				case SONG_AUDIO:
					return findLib('songs/${PlayState.SONG.songName.toLowerCase()}/audio/$fileName.ogg');
				case ANIMATED:
					return getAnimated(fileName);
				case XML:
					return findLib(fileName + '.xml');
				case SONG_SCRIPT:
					return findLib('songs/${PlayState.SONG.songName.toLowerCase()}/scripts/$fileName.hx');
				case SHADERS:
					return findLib('shaders/$fileName.frag');
				// scripting
				case STATE, STATES:
					return findLib(resolveScript('source/states/$fileName'));
				case SUBSTATES, SUBSTATE:
					return findLib(resolveScript('source/substates/$fileName'));
				case SCRIPT:
					return findLib(resolveScript('scripts/$fileName'));
				default:
					return findLib(fileName);
			}
		} catch (e:Dynamic) {
			Trace.traceOnce('Paths: "$fileName" not found: $e', true);
			return null;
		}
	}

	public static function findLib(file:String):String {
		if (pathCache.exists(file))
			return pathCache.get(file);

		for (lib in libs) {
			if (FileSystem.exists('$lib/$file')) {
				var foundPath = '$lib/$file';
				pathCache.set(file, foundPath);
				return foundPath;
			}
		}
		pathCache.set(file, null);
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

	public static function resolveScript(fileName:String):String {
		var extensions = ['.hx', '.lua', '.hxc'];

		for (ext in extensions) {
			if (FileSystem.exists(fileName + ext)) {
				return fileName + ext;
			}
		}

		return fileName + '.hx';
	}

	public static function getAnimated(fileName:String):Dynamic {
		// atlas texture
		if (cache.exists(fileName))
			return cache.get(fileName);

		var result:Dynamic = null;
		var imagePath = getPath(fileName, IMAGE);

		var folder = findLib('images/$fileName');
		if (folder != null && FileSystem.exists('$folder/Animation.json'))
			result = FlxAnimateFrames.fromAnimate(folder);

		if (result == null) {
			var xml = findLib('images/$fileName.xml');
			if (xml != null)
				result = FlxAtlasFrames.fromSparrow(imagePath, xml);
		}

		if (result == null) {
			var txt = findLib('images/$fileName.txt');
			if (txt != null)
				result = FlxAtlasFrames.fromLibGdx(imagePath, txt);
		}

		if (result == null) {
			var json = findLib('images/$fileName.json');
			if (json != null)
				result = FlxAtlasFrames.fromTexturePackerJson(imagePath, json);
		}

		if (result == null) {
			var png = imagePath;
			if (png != null)
				result = png;
		}

		if (result != null)
			cache.set(fileName, result);

		return result;
	}

	public static function cacheAutoAsync(fileName:String, onComplete:Dynamic->Void):Void {
		if (cache.exists(fileName)) {
			if (onComplete != null)
				onComplete(cache.get(fileName));
			return;
		}

		var imagePath = getPath(fileName, IMAGE);
		if (imagePath == null) {
			Trace.traceOnce('cacheAutoAsync: Not found $fileName', true);
			if (onComplete != null)
				onComplete(null);
			return;
		}

		// CPU / RAM
		Thread.create(function() {
			var bmp = openfl.display.BitmapData.fromFile(imagePath);

			var formatDetected = "image";
			var rawData:String = null;
			var folderPath:String = null;

			var animFolder = findLib('images/$fileName');
			if (animFolder != null && FileSystem.exists('$animFolder/Animation.json')) {
				formatDetected = "animate";
				folderPath = animFolder;
			} else {
				var xmlPath = findLib('images/$fileName.xml');
				if (xmlPath != null) {
					formatDetected = "sparrow";
					rawData = File.getContent(xmlPath);
				} else {
					var jsonPath = findLib('images/$fileName.json');
					if (jsonPath != null) {
						formatDetected = "json";
						rawData = File.getContent(jsonPath);
					} else {
						var txtPath = findLib('images/$fileName.txt');
						if (txtPath != null) {
							formatDetected = "pack";
							rawData = File.getContent(txtPath);
						}
					}
				}
			}

			// VRAM
			haxe.MainLoop.runInMainThread(function() {
				var finalAsset:Dynamic = null;

				if (bmp != null && !cache.exists(fileName)) {
					// UPLOAD IN OPENFL
					var graphic = flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, fileName);
					graphic.persist = true;

					switch (formatDetected) {
						case "animate":
							finalAsset = FlxAnimateFrames.fromAnimate(folderPath);
						case "sparrow":
							finalAsset = FlxAtlasFrames.fromSparrow(graphic, rawData);
						case "json":
							finalAsset = FlxAtlasFrames.fromTexturePackerJson(graphic, rawData);
						case "pack":
							finalAsset = FlxAtlasFrames.fromLibGdx(graphic, rawData);
						default: // "image"
							finalAsset = graphic;
					}

					if (finalAsset != null) {
						cache.set(fileName, finalAsset);
					}
				} else if (bmp != null) {
					bmp.dispose();
				}

				if (onComplete != null) {
					onComplete(cache.get(fileName) ?? finalAsset);
				}
			});
		});
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
		pathCache.clear();
		FunkinSprite.cacheOffsets.clear();

		openfl.system.System.gc();
	}
}

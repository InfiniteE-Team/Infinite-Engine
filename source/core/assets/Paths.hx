package core.assets;

import sys.io.File;
import animate.FlxAnimateFrames;
import sys.FileSystem;
import game.PlayState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;

class Paths {
	private static var pathCache = new Map<String, String>();
	private static var cache = new Map<String, Dynamic>();

	public static function getPath(fileName:String, ?type:core.enums.AssetType = DEFAULT):Dynamic {
		try {
			switch (type) {
				case DATA:
					return Library.findLib("data/" + fileName);
				case JSON:
					return Library.findLib(fileName + '.json');
				case FONT:
					return Library.findLib("fonts/" + fileName);
				case IMAGE:
					return Library.findLib("images/" + fileName + '.png');
				case SOUND:
					return Library.findLib("sounds/" + fileName + '.ogg');
				case MUSIC:
					return Library.findLib("music/" + fileName + '.ogg');
				case SONG_AUDIO:
					return Library.findLib('songs/${PlayState.instance.curSong}/audio/$fileName.ogg');
				case ANIMATED:
					return getAnimated(fileName);
				case XML:
					return Library.findLib(fileName + '.xml');
				case SONG_SCRIPT:
					return Library.findLib('songs/${PlayState.instance.curSong}/scripts/$fileName.hx');
				case SHADERS:
					return Library.findLib('shaders/$fileName.frag');
				// scripting
				case STATES:
					return Library.findLib(resolveScript('source/states/$fileName'));
				case SUBSTATES:
					return Library.findLib(resolveScript('source/substates/$fileName'));
				case TYPEDEFS:
					return Library.findLib(resolveScript('source/typedefs/$fileName'));
				case SCRIPT:
					return Library.findLib(resolveScript('scripts/$fileName'));
				default:
					return Library.findLib(fileName);
			}
		} catch (e:Dynamic) {
			Trace.traceOnce('Paths: "$fileName" not found: $e', true);
			return null;
		}
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
		var resolvedPath = Library.findLib('images/$fileName.png') ?? Library.findLib('images/$fileName');
		var cacheKey = resolvedPath ?? fileName;

		if (cache.exists(cacheKey))
			return cache.get(cacheKey);

		var imagePath = getPath(fileName, 'image');
		var folder = resolvedPath;
		var result:Dynamic = null;

		var graphic:flixel.graphics.FlxGraphic = null;
		if (imagePath != null) {
			graphic = FlxG.bitmap.get(cacheKey);
			if (graphic == null) {
				var bmp = openfl.display.BitmapData.fromFile(imagePath);
				graphic = flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, cacheKey);
				graphic.persist = true;

				@:privateAccess
				graphic.bitmap.getTexture(FlxG.stage.context3D);
				graphic.bitmap.disposeImage();
			}
		}

		inline function tryLib(ext:String, build:flixel.graphics.FlxGraphic->String->Dynamic):Bool {
			var path = Library.findLib('images/$fileName$ext');
			if (path != null && graphic != null) {
				result = build(graphic, path);
				return true;
			}
			return false;
		}

		if (folder != null && FileSystem.exists('$folder/Animation.json')) {
			result = FlxAnimateFrames.fromAnimate(folder);
		} else {
			tryLib('.xml', (g, p) -> FlxAtlasFrames.fromSparrow(g, p))
			|| tryLib('.txt', (g, p) -> FlxAtlasFrames.fromLibGdx(g, p))
			|| tryLib('.json', (g, p) -> FlxAtlasFrames.fromTexturePackerJson(g, p))
			|| (result = graphic) != null;
		}

		if (result != null && !(result is FlxAtlasFrames))
			cache.set(cacheKey, result);

		if ((result is FlxFramesCollection)) {
			var fc:FlxFramesCollection = cast result;
			if (fc.parent != null && fc.parent.bitmap != null) {
				fc.parent.persist = true;
				@:privateAccess
				fc.parent.bitmap.getTexture(FlxG.stage.context3D);
				fc.parent.bitmap.disposeImage();
			}
		}

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
		sys.thread.Thread.create(function() {
			var img = lime.graphics.Image.fromFile(imagePath);

			var formatDetected = "image";
			var rawData:String = null;
			var folderPath:String = null;

			var animFolder = Library.findLib('images/$fileName');
			if (animFolder != null && FileSystem.exists('$animFolder/Animation.json')) {
				formatDetected = "animate";
				folderPath = animFolder;
			} else {
				var xmlPath = Library.findLib('images/$fileName.xml');
				if (xmlPath != null) {
					formatDetected = "sparrow";
					rawData = File.getContent(xmlPath);
				} else {
					var jsonPath = Library.findLib('images/$fileName.json');
					if (jsonPath != null) {
						formatDetected = "json";
						rawData = File.getContent(jsonPath);
					} else {
						var txtPath = Library.findLib('images/$fileName.txt');
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

				if (img != null && !cache.exists(fileName)) {
					// UPLOAD IN OPENFL
					var bmp = openfl.display.BitmapData.fromImage(img);
					var graphic = flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, fileName);
					graphic.persist = true;

					@:privateAccess
					graphic.bitmap.getTexture(FlxG.stage.context3D);

					graphic.bitmap.disposeImage();
					img.buffer = null;
					img = null;

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

					if ((finalAsset is FlxFramesCollection)) {
						var fc:FlxFramesCollection = cast finalAsset;
						if (fc.parent != null)
							fc.parent.persist = true;
					}

					if (finalAsset != null) {
						cache.set(fileName, finalAsset);
					}
				} else if (img != null) {
					img.buffer = null;
					img = null;
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
				if (frames.parent != null) {
					frames.parent.bitmap.dispose();
					FlxG.bitmap.remove(frames.parent);
				}
				frames.destroy();
			} else if (asset is flixel.graphics.FlxGraphic) {
				var asset = cast(asset, flixel.graphics.FlxGraphic);
				if (asset.bitmap != null)
					asset.bitmap.dispose();
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

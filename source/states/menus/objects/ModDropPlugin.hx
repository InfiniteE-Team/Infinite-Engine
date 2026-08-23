package states.menus.objects;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import haxe.zip.Reader;
import lime.app.Application;

class ModDropPlugin {
	var bg:flixel.FlxSprite;
	var dropIndicator:core.assets.FunkinSprite;
	var parentState:flixel.FlxState;
	var onComplete:Void->Void;

	public function new(parent:flixel.FlxState, ?onCompleteCallback:Void->Void) {
		this.parentState = parent;
		this.onComplete = onCompleteCallback;

		bg = new flixel.FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.screenCenter();
		bg.visible = false;
		bg.alpha = 0.4;
		parentState.add(bg);

		dropIndicator = new core.assets.FunkinSprite(0, 0, true);
		dropIndicator.loadGraphic(Paths.getPath('menus/mods/drop-hover', 'image'));
		dropIndicator.visible = false;
		dropIndicator.scale.set(0.8, 0.8);
		dropIndicator.updateHitbox();
		dropIndicator.screenCenter();
		parentState.add(dropIndicator);

		Application.current.window.onDropFile.add(onDropFile);
	}

	function onDropFile(path:String):Void {
		if (StringTools.endsWith(path.toLowerCase(), ".zip")) {
			trace("Installing mod since: " + path);

			dropIndicator.visible = bg.visible = true;

			flixel.util.FlxTimer.wait(0.1, () -> {
				installModZIP(path, "mods/");

				dropIndicator.visible = bg.visible = false;

				if (onComplete != null) {
					onComplete();
				}
			});
		} else {
			var cleanPath = path.split("\\").join("/");
			if (StringTools.endsWith(cleanPath, "/")) {
				cleanPath = cleanPath.substring(0, cleanPath.length - 1);
			}

			if (FileSystem.exists(cleanPath) && FileSystem.isDirectory(cleanPath)) {
				trace("Installing mod since folder: " + cleanPath);

				dropIndicator.visible = bg.visible = true;

				flixel.util.FlxTimer.wait(0.1, () -> {
					var folderName = cleanPath.split("/").pop();
					var destPath = Path.join(["mods", folderName]);

					copyDirectory(cleanPath, destPath);

					dropIndicator.visible = bg.visible = false;

					if (onComplete != null) {
						onComplete();
					}
				});
			} else
				trace("MOD FORMAT ERROR!");
		}
	}

	function installModZIP(root:String, destination:String):Void {
		try {
			var file = File.read(root);
			var entries = Reader.readZip(file);
			file.close();

			for (entry in entries) {
				var fileName = entry.fileName;
				var fullPath = Path.join([destination, fileName]);

				if (StringTools.endsWith(fileName, "/") || StringTools.endsWith(fileName, "\\")) {
					if (!FileSystem.exists(fullPath))
						FileSystem.createDirectory(fullPath);
				} else {
					var dir = Path.directory(fullPath);
					if (!FileSystem.exists(dir))
						FileSystem.createDirectory(dir);

					var data = Reader.unzip(entry);
					File.saveBytes(fullPath, data);
				}
			}
			trace("Mod extracted successfully!");
		} catch (e:Dynamic) {
			trace("Error extracting: " + e);
		}
	}

	function copyDirectory(source:String, destination:String):Void {
		try {
			if (!FileSystem.exists(destination)) {
				FileSystem.createDirectory(destination);
			}
			var files = FileSystem.readDirectory(source);
			for (file in files) {
				var srcPath = Path.join([source, file]);
				var destPath = Path.join([destination, file]);
				if (FileSystem.isDirectory(srcPath)) {
					copyDirectory(srcPath, destPath);
				} else {
					File.copy(srcPath, destPath);
				}
			}
		} catch (e:Dynamic) {
			trace("Error copying folder: " + e);
		}
	}

	public function destroy():Void {
		Application.current.window.onDropFile.remove(onDropFile);
		if (dropIndicator != null) {
			dropIndicator.destroy();
		}
	}
}

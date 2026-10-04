package states.menus.objects;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import haxe.zip.Reader;
import lime.app.Application;

class ModDropPlugin {
	static final MAX_COPY_DEPTH:Int = 32;

	var bg:flixel.FlxSprite;
	var dropIndicator:core.assets.FunkinSprite;
	var parentState:flixel.FlxState;
	var onComplete:Void->Void;

	var destroyed:Bool = false;

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
				if (destroyed)
					return;

				var installed = installModZIP(path, "mods/");

				dropIndicator.visible = bg.visible = false;

				if (installed && onComplete != null) {
					onComplete();
				}
			});
		} else {
			var cleanPath = path.split("\\").join("/");
			if (StringTools.endsWith(cleanPath, "/")) {
				cleanPath = cleanPath.substring(0, cleanPath.length - 1);
			}

			if (FileSystem.exists(cleanPath) && FileSystem.isDirectory(cleanPath)) {
				var folderName = cleanPath.split("/").pop();

				if (folderName == null || folderName == "" || folderName == "." || folderName == "..") {
					trace("MOD FORMAT ERROR! Invalid folder name: " + cleanPath);
					return;
				}

				var destPath = Path.join(["mods", folderName]);

				if (FileSystem.exists(destPath)) {
					rejectInstall(folderName);
					return;
				}

				trace("Installing mod since folder: " + cleanPath);

				dropIndicator.visible = bg.visible = true;

				flixel.util.FlxTimer.wait(0.1, () -> {
					if (destroyed)
						return;

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

	function rejectInstall(modName:String):Void {
		trace('Mod "$modName" is already installed, nothing was copied. Delete it first (Delete key in the mods menu) if you want to install it again.');
		FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
	}

	function rejectUnsafe(entryName:String):Void {
		trace('Zip rejected, nothing was extracted. It contains an unsafe path: "$entryName"');
		FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
	}

	static function isSafeZipPath(name:String):Bool {
		var clean = name.split("\\").join("/");

		if (clean == "")
			return false;

		if (clean.charAt(0) == "/")
			return false;

		if (clean.length > 1 && clean.charAt(1) == ":")
			return false;

		for (part in clean.split("/")) {
			if (part == "..")
				return false;
		}

		return true;
	}

	static function isJunkZipEntry(name:String):Bool {
		var clean = name.split("\\").join("/");

		return StringTools.startsWith(clean, "__MACOSX/") || clean == ".DS_Store" || StringTools.endsWith(clean, "/.DS_Store");
	}

	function installModZIP(root:String, destination:String):Bool {
		try {
			var file = File.read(root);
			var entries = Reader.readZip(file);
			file.close();

			for (entry in entries) {
				if (isJunkZipEntry(entry.fileName))
					continue;

				if (!isSafeZipPath(entry.fileName)) {
					rejectUnsafe(entry.fileName);
					return false;
				}

				var cleanName = entry.fileName.split("\\").join("/");
				var slash = cleanName.indexOf("/");
				if (slash > 0) {
					var topFolder = cleanName.substr(0, slash);
					if (FileSystem.exists(Path.join([destination, topFolder]))) {
						rejectInstall(topFolder);
						return false;
					}
				}
			}

			var modsRoot = Path.addTrailingSlash(Path.normalize(destination));

			for (entry in entries) {
				var fileName = entry.fileName;

				if (isJunkZipEntry(fileName))
					continue;

				var fullPath = Path.join([destination, fileName]);

				if (!StringTools.startsWith(Path.normalize(fullPath), modsRoot)) {
					rejectUnsafe(fileName);
					return false;
				}

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

		return true;
	}

	function copyDirectory(source:String, destination:String, depth:Int = 0):Void {
		if (depth > MAX_COPY_DEPTH) {
			trace("Folder is nested too deep, skipping: " + source);
			return;
		}

		try {
			if (!FileSystem.exists(destination)) {
				FileSystem.createDirectory(destination);
			}
			var files = FileSystem.readDirectory(source);
			for (file in files) {
				if (file == ".git" || file == ".DS_Store")
					continue;

				var srcPath = Path.join([source, file]);
				var destPath = Path.join([destination, file]);
				if (FileSystem.isDirectory(srcPath)) {
					copyDirectory(srcPath, destPath, depth + 1);
				} else {
					File.copy(srcPath, destPath);
				}
			}
		} catch (e:Dynamic) {
			trace("Error copying folder: " + e);
		}
	}

	public function destroy():Void {
		destroyed = true;
		Application.current.window.onDropFile.remove(onDropFile);
		if (dropIndicator != null) {
			dropIndicator.destroy();
		}
		if (bg != null) {
			bg.destroy();
		}
	}
}
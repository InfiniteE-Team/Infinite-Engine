package states.menus.objects;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import haxe.zip.Reader;
import lime.app.Application;
import sys.thread.Thread;
import sys.thread.Mutex;
import game.objects.Camera;

class ModDropPlugin {
	var cam:Camera;

	static final MAX_COPY_DEPTH:Int = 32;

	var bg:flixel.FlxSprite;
	var dropIndicator:core.assets.FunkinSprite;
	var parentState:flixel.FlxState;
	var onComplete:Void->Void;

	var destroyed:Bool = false;

	var progressBg:flixel.FlxSprite;
	var progressBar:flixel.FlxSprite;
	var progressLabel:flixel.text.FlxText;

	static final BAR_W:Int = 500;
	static final BAR_H:Int = 22;
	static final BAR_Y:Int = 430;

	var mutex:Mutex = new Mutex();
	var _progress:Float = 0.0;
	var _statusMsg:String = '';
	var _done:Bool = false;
	var _success:Bool = false;
	var _abort:Bool = false;

	public function new(parent:flixel.FlxState, ?onCompleteCallback:Void->Void, ?cam:Camera) {
		this.parentState = parent;
		this.onComplete = onCompleteCallback;
		this.cam = cam;

		bg = new flixel.FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.screenCenter();
		bg.visible = false;
		bg.alpha = 0.6;
		parentState.add(bg);

		dropIndicator = new core.assets.FunkinSprite(0, 0, true);
		dropIndicator.loadGraphic(Paths.getPath('menus/mods/drop-hover', 'image'));
		dropIndicator.visible = false;
		dropIndicator.scale.set(0.95, 0.95);
		dropIndicator.updateHitbox();
		dropIndicator.screenCenter();
		parentState.add(dropIndicator);

		var barX:Float = (FlxG.width - BAR_W) * 0.5;
		progressBg = new flixel.FlxSprite(barX, BAR_Y);
		progressBg.makeGraphic(BAR_W, BAR_H, 0xFF444444);
		progressBg.visible = false;
		progressBg.scrollFactor.set(0, 0);
		parentState.add(progressBg);

		progressBar = new flixel.FlxSprite(barX, BAR_Y);
		progressBar.makeGraphic(1, BAR_H, 0xFFFFFF00);
		progressBar.visible = false;
		progressBar.scrollFactor.set(0, 0);
		parentState.add(progressBar);

		progressLabel = new flixel.text.FlxText(0, BAR_Y + BAR_H + 8, FlxG.width, '');
		progressLabel.setFormat(Paths.getPath('Funkin.otf', 'font'), 22, 0xFFFFFFFF, "center");
		progressLabel.antialiasing = SaveData.data.antialiasing;
		progressLabel.scrollFactor.set(0, 0);
		progressLabel.visible = false;
		parentState.add(progressLabel);

		if (cam != null) {
			bg.cameras = [cam];
			dropIndicator.cameras = [cam];
			progressBg.cameras = [cam];
			progressBar.cameras = [cam];
			progressLabel.cameras = [cam];
		}

		Application.current.window.onDropFile.add(onDropFile);

		parentState.add(new ProgressUpdater(this));
	}

	public function tickUpdate(elapsed:Float):Void {
		if (destroyed)
			return;

		mutex.acquire();
		var p = _progress;
		var msg = _statusMsg;
		var done = _done;
		var success = _success;
		mutex.release();

		if (progressBar.visible) {
			var targetW = Std.int(BAR_W * p);
			if (targetW < 1)
				targetW = 1;
			progressBar.setGraphicSize(targetW, BAR_H);
			progressBar.updateHitbox();
			progressLabel.text = msg;
		}

		if (done) {
			mutex.acquire();
			_done = false;
			mutex.release();

			hideProgress();
			if (success && onComplete != null)
				onComplete();
		}
	}

	function onDropFile(path:String):Void {
		if (StringTools.endsWith(path.toLowerCase(), ".zip")) {
			trace("Installing mod since: " + path);
			showProgress("Reading ZIP...");
			Thread.create(() -> workerInstallZIP(path, "mods/"));
		} else {
			var cleanPath = path.split("\\").join("/");
			if (StringTools.endsWith(cleanPath, "/"))
				cleanPath = cleanPath.substring(0, cleanPath.length - 1);

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
				showProgress("Counting files...");
				Thread.create(() -> workerCopyFolder(cleanPath, destPath));
			} else
				trace("MOD FORMAT ERROR!");
		}
	}

	static final MOD_CONTENT_FOLDERS:Array<String> = [
		'data',
		'songs',
		'images',
		'scripts',
		'sounds',
		'music',
		'shaders',
		'videos',
		'fonts',
		'source'
	];

	static final MOD_CONTENT_FOLDERS_NEW:Array<String> = ['gameplay', 'ui'];

	function showProgress(msg:String):Void {
		dropIndicator.visible = bg.visible = true;
		progressBg.visible = progressBar.visible = progressLabel.visible = true;
		progressLabel.text = msg;
		progressBar.setGraphicSize(1, BAR_H);
		progressBar.updateHitbox();
		mutex.acquire();
		_progress = 0;
		_statusMsg = msg;
		_done = false;
		_success = false;
		_abort = false;
		mutex.release();
	}

	function hideProgress():Void {
		dropIndicator.visible = bg.visible = false;
		progressBg.visible = progressBar.visible = progressLabel.visible = false;
	}

	function setProgress(p:Float, msg:String):Void {
		mutex.acquire();
		_progress = p;
		_statusMsg = msg;
		mutex.release();
	}

	function setDone(success:Bool):Void {
		mutex.acquire();
		_done = true;
		_success = success;
		if (success)
			_progress = 1.0;
		mutex.release();
	}

	function shouldAbort():Bool {
		mutex.acquire();
		var a = _abort || destroyed;
		mutex.release();
		return a;
	}

	function workerInstallZIP(root:String, destination:String):Void {
		var created:Array<String> = [];
		try {
			var file = File.read(root);
			var entries = Reader.readZip(file);
			file.close();

			var tops:Array<String> = [];
			var loose:Bool = false;
			var hasFolders:Bool = false;
			for (entry in entries) {
				if (isJunkZipEntry(entry.fileName))
					continue;
				if (!isSafeZipPath(entry.fileName)) {
					rejectUnsafe(entry.fileName);
					setDone(false);
					return;
				}
				var cleanName = entry.fileName.split("\\").join("/");
				var slash = cleanName.indexOf("/");
				if (slash <= 0)
					continue;
				hasFolders = true;
				var top = cleanName.substr(0, slash);
				if (MOD_CONTENT_FOLDERS.contains(top.toLowerCase()))
					loose = true;
				if (!tops.contains(top))
					tops.push(top);
			}
			if (!hasFolders)
				loose = true;

			var prefix:String = loose ? Path.withoutExtension(Path.withoutDirectory(root.split("\\").join("/"))) : null;
			var targets:Array<String> = prefix != null ? [prefix] : tops;
			if (targets.length == 0) {
				trace("MOD FORMAT ERROR! The zip is empty: " + root);
				setDone(false);
				return;
			}
			for (target in targets) {
				if (FileSystem.exists(Path.join([destination, target]))) {
					rejectInstall(target);
					setDone(false);
					return;
				}
			}

			var modsRoot = Path.addTrailingSlash(Path.normalize(destination));
			created = targets.copy();

			var realEntries:Array<haxe.zip.Entry> = [];
			for (entry in entries) {
				if (isJunkZipEntry(entry.fileName))
					continue;
				if (prefix == null && entry.fileName.split("\\").join("/").indexOf("/") <= 0)
					continue;
				if (!StringTools.endsWith(entry.fileName, "/") && !StringTools.endsWith(entry.fileName, "\\"))
					realEntries.push(entry);
			}
			var total = realEntries.length;
			var done = 0;

			for (entry in entries) {
				if (shouldAbort()) {
					cleanup(destination, created);
					setDone(false);
					return;
				}

				var fileName = entry.fileName;
				if (isJunkZipEntry(fileName))
					continue;
				if (prefix == null && fileName.split("\\").join("/").indexOf("/") <= 0)
					continue;

				var fullPath = prefix != null ? Path.join([destination, prefix, fileName]) : Path.join([destination, fileName]);

				if (!StringTools.startsWith(Path.normalize(fullPath), modsRoot)) {
					rejectUnsafe(fileName);
					cleanup(destination, created);
					setDone(false);
					return;
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
					done++;
					setProgress(total > 0 ? done / total : 1.0, 'Extracting... $done / $total files');
				}
			}
			trace("Mod extracted successfully!");
			setDone(true);
		} catch (e:Dynamic) {
			Console.log("Error extracting, the half-installed mod was removed: " + e, true);
			FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
			cleanup(destination, created);
			setDone(false);
		}
	}

	function workerCopyFolder(source:String, destination:String):Void {
		try {
			var allFiles:Array<{src:String, dst:String}> = [];
			collectFiles(source, destination, allFiles, 0);

			var total = allFiles.length;
			var done = 0;

			for (pair in allFiles) {
				if (shouldAbort()) {
					setDone(false);
					return;
				}
				var dir = Path.directory(pair.dst);
				if (!FileSystem.exists(dir))
					FileSystem.createDirectory(dir);
				File.copy(pair.src, pair.dst);
				done++;
				setProgress(total > 0 ? done / total : 1.0, 'Copying... $done / $total files');
			}

			setDone(true);
		} catch (e:Dynamic) {
			trace("Error copying folder: " + e);
			setDone(false);
		}
	}

	function collectFiles(src:String, dst:String, out:Array<{src:String, dst:String}>, depth:Int):Void {
		if (depth > MAX_COPY_DEPTH)
			return;
		if (!FileSystem.exists(dst))
			FileSystem.createDirectory(dst);
		for (file in FileSystem.readDirectory(src)) {
			if (file == ".git" || file == ".DS_Store")
				continue;
			var srcPath = Path.join([src, file]);
			var destPath = Path.join([dst, file]);
			if (FileSystem.isDirectory(srcPath))
				collectFiles(srcPath, destPath, out, depth + 1);
			else
				out.push({src: srcPath, dst: destPath});
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

	function cleanup(destination:String, created:Array<String>):Void {
		for (target in created) {
			if (!FileSystem.exists(Path.join([destination, target])))
				continue;
			try {
				deleteFolder(Path.join([destination, target]));
			} catch (e:Dynamic) {
				Console.log('Could not clean up "$target": $e', true);
			}
		}
	}

	function deleteFolder(path:String):Void {
		for (entry in FileSystem.readDirectory(path)) {
			var child = Path.join([path, entry]);
			if (FileSystem.isDirectory(child))
				deleteFolder(child);
			else
				FileSystem.deleteFile(child);
		}
		FileSystem.deleteDirectory(path);
	}

	public function destroy():Void {
		destroyed = true;
		mutex.acquire();
		_abort = true;
		mutex.release();
		Application.current.window.onDropFile.remove(onDropFile);
		if (dropIndicator != null)
			dropIndicator.destroy();
		if (bg != null)
			bg.destroy();
		if (progressBg != null)
			progressBg.destroy();
		if (progressBar != null)
			progressBar.destroy();
		if (progressLabel != null)
			progressLabel.destroy();
	}
}

private class ProgressUpdater extends flixel.FlxBasic {
	var plugin:ModDropPlugin;

	public function new(p:ModDropPlugin) {
		super();
		plugin = p;
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		plugin.tickUpdate(elapsed);
	}
}

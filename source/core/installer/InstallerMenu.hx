package core.installer;

import sys.io.File;
import sys.FileSystem;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import core.assets.FunkinSprite;

class InstallerMenu extends MusicBeatState {
	var bg:FlxSprite = new FlxSprite();
	var files:FlxSprite = new FlxSprite();
	var configMenu:FunkinSprite;

	var installing:Bool = false;

	var modinAssets:Bool = false;

	var importBtn:FlxSprite;

	public function new() {
		super();
		// Constructor for the installer menu
	}

	override public function create() {
		generateMenu();

		generateImportButton();

		super.create();
	}

	public function generateMenu():Void {
		// Code to generate the installer menu based on MenuData
		bg.loadGraphic(Paths.getPath('menus/installer/BG_installer', 'image'));
		bg.screenCenter();
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		configMenu = new FunkinSprite(70, 40);
		configMenu.frames = Paths.getAnimated('menus/installer/config_window');
		configMenu.anim.addBySymbol('Clp', 'Clp', 24, false);
		configMenu.playAnim('Clp');
		configMenu.antialiasing = SaveData.data.antialiasing;
		configMenu.scale.set(0.94, 0.94);
		configMenu.updateHitbox();
		add(configMenu);

		files.frames = Paths.getPath('menus/installer/images_yep', 'animated');
		files.animation.addByPrefix('idle', 'files', 24, false);
		files.animation.play('idle');
		files.antialiasing = SaveData.data.antialiasing;
		files.screenCenter();
		files.x += 190;
		files.scrollFactor.set(0, 0);
		files.scale.set(0.92, 0.92);
		files.updateHitbox();
		add(files);
	}

	function generateImportButton():Void {
		importBtn = new FlxSprite(FlxG.width * 0.5 - 60, 10);
		importBtn.makeGraphic(120, 30, FlxColor.WHITE);
		add(importBtn);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(importBtn)) {
			onImportPressed();
		}
	}

	function onImportPressed():Void {
		if (installing)
			return;

		installFiles('assets');
	}

	public function installFiles(folder:String):Void {
		var resolved = core.assets.Library.findLib(folder);
		if (resolved == null || !FileSystem.exists(resolved))
			return;

		installing = true;
		modinAssets = false;

		for (file in FileSystem.readDirectory(resolved)) {
			if (file.startsWith('assets/'))
				modinAssets = true;
		}

		copyFolder(resolved, 'assets');

		afterInstall();
	}

	function copyFolder(src:String, dst:String):Void {
		if (!FileSystem.exists(dst))
			FileSystem.createDirectory(dst);

		for (item in FileSystem.readDirectory(src)) {
			var srcPath = '$src/$item';
			var dstPath = '$dst/$item';

			if (FileSystem.isDirectory(srcPath)) {
				copyFolder(srcPath, dstPath);
			} else {
				File.saveBytes(dstPath, File.getBytes(srcPath));
			}
		}
	}

	public static function hasAssetFiles(folder:String):Bool {
		if (!sys.FileSystem.exists(folder))
			return false;

		for (item in sys.FileSystem.readDirectory(folder)) {
			var path = '$folder/$item';
			if (sys.FileSystem.isDirectory(path)) {
				if (hasAssetFiles(path))
					return true;
			} else {
				if (!item.startsWith('.') && item != 'Thumbs.db' && item != 'desktop.ini')
					return true;
			}
		}
		return false;
	}

	function afterInstall():Void {
		var targetState = core.ConfigMain.globalData.startState;
		MusicBeatState.switchState(() -> Type.createInstance(targetState, []));
	}

	public function changeSection():Void {}

	public function hide():Void {}
}

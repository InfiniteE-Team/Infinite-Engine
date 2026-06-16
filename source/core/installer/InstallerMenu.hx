package core.installer;
import flixel.FlxSprite;
import core.assets.FunkinSprite;

class InstallerMenu extends MusicBeatState {
	var bg:FlxSprite = new FlxSprite();
	var files:FlxSprite = new FlxSprite();
	var configMenu:FunkinSprite;

    var installing:Bool = false;

	var modinAssets:Bool = false;

	public function new() {
		super();
		// Constructor for the installer menu
	}

	override public function create() {
		generateMenu();

		super.create();
	}

	public function generateMenu():Void {
		// Code to generate the installer menu based on MenuData
		bg.loadGraphic(Paths.getPath('installer/BG_installer', 'image'));
		bg.screenCenter();
		bg.antialiasing = true;
		bg.scrollFactor.set(0, 0);
		add(bg);

		configMenu = new FunkinSprite(70,40);
		configMenu.frames = Paths.getAnimated('installer/config_window');
		configMenu.anim.addBySymbol('Clp','Clp',24,false);
		configMenu.playAnim('Clp');
		configMenu.antialiasing = true;
		configMenu.scale.set(0.94,0.94);
		configMenu.updateHitbox();
		add(configMenu);

		files.frames = Paths.getPath('installer/images_yep', 'animated');
        files.animation.addByPrefix('idle','files',24,false);
		files.animation.play('idle');
		files.antialiasing = true;
		files.screenCenter();
		files.x += 190;
		files.scrollFactor.set(0, 0);
		files.scale.set(0.92,0.92);
		files.updateHitbox();
		add(files);
	}

    public function installFiles(folder:String):Void {
        // Code to handle the installation of files
		var resolved = Paths.findLib(folder);
		if (resolved == null || !sys.FileSystem.exists(resolved))
			return;
		for (file in sys.FileSystem.readDirectory(resolved)) {
			if (file.startsWith('assets/'))
				modinAssets = true;
		}
    }

	public function changeSection():Void {
		// Code to display the installer menu
	}

	public function hide():Void {
		// Code to hide the installer menu
	}
}

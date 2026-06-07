package core.installer;

class InstallerMenu extends states.MusicBeatState {
	var bg:FlxSprite = new FlxSprite();
	var files:FlxSprite = new FlxSprite();

    
    var installing:Bool = false;

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
		bg.scrollFactor.set(0, 0);
		add(bg);

		files.frames = Paths.getPath('installer/images_yep', 'animated');
        files.animation.addByPrefix('','',24,false);
		files.screenCenter();
		files.scrollFactor.set(0, 0);
		add(files);
	}

    public function installFiles():Void {
        // Code to handle the installation of files

    }

	public function changeSection():Void {
		// Code to display the installer menu
	}

	public function hide():Void {
		// Code to hide the installer menu
	}
}

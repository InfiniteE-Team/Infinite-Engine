package;

class StageEditor extends ScriptState {
	public var defaultZoom:Int = 0.4;
	public var curStage:String = 'stage';
	public var elements:Array<Dynamic> = [];

	var camEditor:Camera;
	var camHud:Camera;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		initCameras();

		Toolkit.init();

		camEditor.zoom = defaultZoom;

		editorHUD();
	}

	function initCameras() {
		camEditor = new Camera();
		camHud = new Camera();
		camHud.bgColor = 0x00000000;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHud, false);
	}

	function editorHUD() {
		var mainLayout = new VBox();
		mainLayout.percentWidth = 100;
		mainLayout.percentHeight = 100;
		mainLayout.cameras = [camHud];

		// top bar
		var menuBar = new MenuBar();
		menuBar.percentWidth = 100;

		var fileMenu = new Menu();
		fileMenu.text = "File";

		menuBar.addComponent(fileMenu);

		mainLayout.addComponent(menuBar);

		Screen.instance.addComponent(mainLayout);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.BACK)
			ScriptClass.switchState('MainMenuState');
	}
}

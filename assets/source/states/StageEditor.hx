class StageEditor extends ScriptState {
	public var defaultZoom:Float = 0.4;
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
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.BACK)
			ScriptClass.switchState('MainMenuState');
	}
}

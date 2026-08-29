import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;

class GameplayEditor extends ScriptState {
	var acceptOption:Bool = false;

	public var gameAudio:GameAudio = new GameAudio();

	var scrollSpeed:Float = 1.4;
	var isPlaying:Bool = false;

	var GRID_SIZE:Int = 32;
	var COLUMNS:Int = 4;
	var TOTAL_ROWS:Int = 256;

	var gridBG:FlxSprite;
	var playhead:FlxSprite;

	public function new() {
		super();
	}

	override public function create() {
		super.create();


		add(gameAudio);

		var gridWidth:Int = COLUMNS * GRID_SIZE;
		var gridHeight:Int = TOTAL_ROWS * GRID_SIZE;
		var gridTexture = FlxGridOverlay.createGrid(GRID_SIZE, GRID_SIZE, gridWidth, gridHeight, true, 0xFF2C2C2C, 0xFF1F1F1F);

		gridBG = new FlxSprite(100, -100).loadGraphic(gridTexture);
		add(gridBG);

		var separator = new FlxSprite(gridBG.x + (GRID_SIZE * 4)).makeGraphic(2, FlxG.height, FlxColor.RED);
		separator.scrollFactor.set(0, 0);
		// add(separator);

		playhead = new FlxSprite(gridBG.x, FlxG.height * 0.5).makeGraphic(GRID_SIZE * COLUMNS, 4, FlxColor.YELLOW);
		playhead.scrollFactor.set(0, 0);
		add(playhead);

		FlxG.mouse.visible = true;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		if (FlxG.keys.justPressed.SPACE) {
			isPlaying = !isPlaying;
		}

		if (isPlaying) {
			gridBG.y -= (scrollSpeed * 200) * elapsed;
		}

		if (FlxG.mouse.wheel != 0) {
			isPlaying = false;
			gridBG.y += FlxG.mouse.wheel * 20;
		}

		var minY:Float = FlxG.height * 0.5 - gridBG.height;
		var maxY:Float = FlxG.height * 0.5;

		if (gridBG.y <= minY) {
			gridBG.y = minY;
			isPlaying = false;
		}
		if (gridBG.y > maxY) {
			gridBG.y = maxY;
		}

		if (Controls.BACK) {
			acceptOption = true;
			MusicBeatState.switchState(() -> new game.PlayState());
		}
	}
}

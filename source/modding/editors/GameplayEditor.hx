package modding.editors;

import game.objects.Camera;
import flixel.util.FlxColor;
import core.rhythm.RhythmCore;
import core.rhythm.audio.GameAudio;
import core.json.song.SongData.SongConfig;
import flixel.addons.display.FlxGridOverlay;

// charting editor and events yep
class GameplayEditor extends MusicBeatState {
	var acceptOption:Bool = false;

	public var gameAudio:GameAudio = new GameAudio();

	public static var SONG:SongConfig;

	var scrollSpeed:Float = 1.4;
	var isPlaying:Bool = false;

	var GRID_SIZE:Int = 32;
	var COLUMNS:Int = 4;
	var TOTAL_ROWS:Int = 256;

	var gridBG:flixel.FlxSprite;
	var playhead:flixel.FlxSprite;

	// cams
	var camEditor:Camera;
	var camHud:Camera;
	var camGameplay:Camera;

	// hud
	var infoHUD:modding.editors.ge.InfoHUD;

	static final SCROLL_MS:Float = 100.0;

	public function new() {
		super();
	}

	function initializeCameras() {
		camEditor = new Camera();
		camHud = new Camera();
		camHud.bgColor.alpha = 0;
		camGameplay = new Camera();
		camGameplay.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHud, false);
		FlxG.cameras.add(camGameplay, false);
	}

	override public function create() {
		super.create();

		initializeCameras();

		add(gameAudio);

		var gridWidth:Int = COLUMNS * GRID_SIZE;
		var gridHeight:Int = TOTAL_ROWS * GRID_SIZE;
		var gridTexture = FlxGridOverlay.createGrid(GRID_SIZE, GRID_SIZE, gridWidth, gridHeight, true, 0xFF2C2C2C, 0xFF1F1F1F);

		gridBG = new flixel.FlxSprite(100, 0).loadGraphic(gridTexture);
		add(gridBG);

		var separator = new flixel.FlxSprite(gridBG.x + (GRID_SIZE * 4)).makeGraphic(2, FlxG.height, FlxColor.RED);
		separator.scrollFactor.set(0, 0);
		// add(separator);

		playhead = new flixel.FlxSprite(gridBG.x, FlxG.height * 0.5).makeGraphic(GRID_SIZE * COLUMNS, 4, FlxColor.YELLOW);
		playhead.scrollFactor.set(0, 0);
		add(playhead);

		infoHUD = new modding.editors.ge.InfoHUD();
		infoHUD.cameras = [camHud];
		add(infoHUD);

		Paths.currentSong = SONG.songName;
		gameAudio.loadSong(SONG, SONG.needVoices, endSong);

		gridBG.y = FlxG.height * 0.5;

		gameAudio.pauseAll();

		RhythmCore.reset(SONG.bpmSong);
		t.reset();

		FlxG.mouse.visible = true;
	}

	function endSong() {
		isPlaying = false;
	}

	override public function update(elapsed:Float) {
		if (isPlaying && gameAudio.inst != null)
			RhythmCore.songPosition = gameAudio.inst.time;

		super.update(elapsed);

		if (acceptOption)
			return;

		infoHUD.updateInfoText(RhythmCore.songPosition, RhythmCore.stepInMs, RhythmCore.bpm);

		if (FlxG.keys.justPressed.SPACE) {
			isPlaying = !isPlaying;
			if (isPlaying) {
				gameAudio.setTime(RhythmCore.songPosition);
				gameAudio.playAll();
				gameAudio.resyncVocals();
			} else {
				RhythmCore.pause(gameAudio);
				gameAudio.pauseAll();
			}
		}

		if (isPlaying)
			gridBG.y -= (scrollSpeed * 200) * elapsed;

		if (FlxG.mouse.wheel != 0 && !isPlaying) {
			var ms:Float = FlxG.keys.pressed.SHIFT ? SCROLL_MS * 4 : SCROLL_MS;
			var delta:Float = -FlxG.mouse.wheel * ms;
			var totalMs:Float = gameAudio.inst != null ? gameAudio.inst.length : 0;

			RhythmCore.songPosition = Math.max(0, Math.min(RhythmCore.songPosition + delta, totalMs));

			var progress:Float = RhythmCore.songPosition / (totalMs > 0 ? totalMs : 1);
			gridBG.y = FlxG.height * 0.5 - gridBG.height * progress;

			gameAudio.setTime(RhythmCore.songPosition);
			t.reset();
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
			gameAudio.stopAll();
			game.PlayState.SONG = SONG;/*
			var startMs = RhythmCore.songPosition;
			MusicBeatState.switchState(() -> {
				var ps = new game.PlayState();
				ps.startTime = startMs;
				return ps;
			});*/
			MusicBeatState.switchState(() -> new game.PlayState());
		}
	}
}

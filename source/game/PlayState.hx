package game;

// camera
import game.objects.Camera;
import game.controllers.CameraController;
// notes
import game.controllers.NoteController;
// visuals
import core.assets.FunkinSprite;
import game.controllers.CharacterController;
import game.objects.sprites.Stage;
// songs
import core.rhythm.RhythmCore;
import core.rhythm.audio.GameAudio;
import core.json.song.SongData.SongConfig;
// saves
import core.config.SaveData;

class PlayState extends MusicBeatState {
	public static var instance:PlayState;

	public var isStoryMode:Bool = false;

	// cameras
	public var camGame:Camera;
	public var camHUD:Camera;
	public var cameraController:CameraController;

	// Song
	public static var SONG:SongConfig = new SongConfig();

	public var gameAudio:GameAudio = new GameAudio();
	public var curSong:String = 'fresh';

	public var noteController:NoteController;

	// visuals
	public var chars:CharacterController;
	public var stage:Stage;

	// configs
	public var saveData:SaveData = new SaveData();

	override public function create() {
		instance = this;
		FlxG.mouse.visible = false;

		#if HSCRIPT_ALLOWED
		initScript();
		script.call("onCreate", []);
		#end

		addCameras();

		SONG.configSong(curSong, '');

		buildStageandChars();

		initSong();

		FlxG.signals.focusLost.add(onFocusLost);
		FlxG.signals.focusGained.add(onFocusGained);

		super.create();

		#if HSCRIPT_ALLOWED
		var songScriptDir = Paths.findLib('songs/$curSong/scripts/');
		if (songScriptDir != null && sys.FileSystem.exists(songScriptDir)) {
			for (file in sys.FileSystem.readDirectory(songScriptDir)) {
				if (file.endsWith('.hx'))
					script.load('$songScriptDir$file');
			}
		}
		script.call("postCreate", []);
		#end
	}

	public function addCameras() {
		camGame = new Camera();
		camHUD = new Camera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		cameraController = new CameraController(camGame, camHUD);
	}

	public function buildStageandChars() {
		script.call("buildStage", []);

		stage = new Stage(SONG.stage);
		stage.cameras = [camGame];

		cameraController.defaultZoom = stage.defaultZoom;
		add(stage);

		chars = new CharacterController('id_');
		stage.charLayer.add(chars);
		for (data in SONG.chars) {
			chars.loadCharacter(data.id, data.name, data.role, stage.charLayer);
			stage.applyCharProps(chars.get(data.id), data.id);
		}

		script.call("postBuildStage", []);
	}

	function buildStrumsandNotes() {
		noteController = new NoteController(SONG, saveData.downscroll, saveData.ghosttaping);
		noteController.strums.cameras = [camHUD];
		noteController.sustains.cameras = [camHUD];
		noteController.notes.cameras = [camHUD];
		add(noteController.strums);
		add(noteController.sustains);
		add(noteController.notes);
	}

	// Code Song
	public function initSong() {
		buildStrumsandNotes();
		noteController.generateNotes(0, SONG);
		gameAudio.loadSong(SONG.needVoices, endSong);
		gameAudio.playAll();
	}

	public function startCountdown() {}

	public function endSong() {}

	// Other screens idk
	public function pauseMenu() {}

	public function isDeath() {}

	override function onFocusLost():Void {
		gameAudio.pauseAll();
	}

	function onFocusGained():Void {
		gameAudio.playAll();
	}

	//

	override public function update(elapsed:Float) {
		#if HSCRIPT_ALLOWED
		script.call("onUpdate", [elapsed]);
		#end

		super.update(elapsed);
		if (gameAudio.inst != null)
			RhythmCore.songPosition = gameAudio.inst.time;

		gameAudio.resyncVocals();

		gameAudio.volumenVocs(SONG,chars.isPlayerMissing(),elapsed);

		cameraController.update(elapsed);

		noteController.update(RhythmCore.songPosition);

		if (chars != null)
			chars.isSinging(noteController, SONG.noteLane);

		#if HSCRIPT_ALLOWED
		script.call("postUpdate", [elapsed]);
		#end
	}

	override public function beatHit() {
		super.beatHit();

		if (beat % 4 == 0)
			cameraController.bumpZoom();

		for (data in SONG.chars) {
			chars.get(data.id).dance();
		}
	}

	override public function destroy() {
		FlxG.signals.focusLost.remove(onFocusLost);
		FlxG.signals.focusGained.remove(onFocusGained);

		FunkinSprite.clearCache();
		if (camGame != null)
			camGame.destroy();
		if (camHUD != null)
			camHUD.destroy();
		if (cameraController != null)
			cameraController.destroy();
		if (gameAudio != null)
			gameAudio.destroy();
		if (chars != null)
			chars.destroy();

		if (noteController != null)
			noteController.destroy();

		if (stage != null)
			stage.destroy();

		instance = null;
		chars = null;
		gameAudio = null;
		stage = null;

		// cameras
		camGame = null;
		camHUD = null;

		noteController = null;

		cameraController = null;

		super.destroy();
	}
}

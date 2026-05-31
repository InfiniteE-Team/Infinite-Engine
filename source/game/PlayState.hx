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
import game.controllers.events.EventManager;
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

	public var events:EventManager = new EventManager();

	public var noteController:NoteController;

	// visuals
	public var chars:CharacterController;
	public var stage:Stage;

	// configs
	public var saveData:SaveData = new SaveData();
	public var playStateConfig:PlayStateConfig = new PlayStateConfig(); // data for health, strum line, etc

	var paused:Bool = false;

	override public function create() {
		instance = this;

		#if HSCRIPT_ALLOWED
		initScript();
		script.load(Paths.getPath('hud', 'script'));
		script.call("onCreate", []);
		#end

		addCameras();

		SONG.configSong(curSong, '');

		buildStageandChars();

		add(gameAudio);

		initSong();

		FlxG.signals.focusLost.add(onFocusLost);
		FlxG.signals.focusGained.add(onFocusGained);

		FlxG.mouse.visible = false;

		super.create();

		#if HSCRIPT_ALLOWED
		var songScriptDir = Paths.findLib('songs/$curSong/scripts/');
		if (songScriptDir != null && sys.FileSystem.exists(songScriptDir)) {
			for (file in sys.FileSystem.readDirectory(songScriptDir)) {
				if (file.endsWith('.hx'))
					script.load('$songScriptDir$file');
			}
		}
		script.executeAll();
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
		#if HSCRIPT_ALLOWED
		script.call("buildStage", []);
		#end

		stage = new Stage(SONG.stage);
		stage.cameras = [camGame];

		cameraController.defaultZoom = stage.defaultZoom;
		cameraController.resolveZoom();
		add(stage);

		chars = new CharacterController();
		stage.charLayer.add(chars);
		for (data in SONG.chars) {
			chars.loadCharacter(data.id, data.name, data.role, stage.charLayer);
			stage.applyCharProps(chars.get(data.id), data.id);
			var stageProps = stage.charProps.get(data.id);
			if (stageProps?.camPos != null) {
				var char = cast(chars.get(data.id), game.objects.sprites.Character);
				if (char != null) {
					char.cameraOffset.x += stageProps.camPos[0];
					char.cameraOffset.y += stageProps.camPos[1];
				}
			}
		}

		cameraController.followChar = cast(chars.get((Lambda.find(SONG.chars,
			c -> CharacterController.namesOpponent.contains(c.role)) ?? SONG.chars[0]).id), game.objects.sprites.Character);

		#if HSCRIPT_ALLOWED
		script.call("postBuildStage", []);
		#end
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

		if (SONG.songData.gameplay.events != null)
			events.loadEvents(SONG.songData.gameplay.events);

		gameAudio.loadSong(SONG.needVoices, endSong);
		gameAudio.playAll();
	}

	public function startCountdown() {}

	public function endSong() {
		// idk what to do here, maybe go to score screen or something? for now just reset the state
		MusicBeatState.resetState();
	}

	// Other screens idk
	public function pauseMenu() {}

	public function isDeath() {
		Trace.traceOnce("isDeath is being called! This should be overridden in a subclass if you want to use it.");

		MusicBeatState.resetState();
	}

	override function onFocusLost():Void {
		gameAudio.pauseAll();
	}

	function onFocusGained():Void {
		gameAudio.playAll();
	}

	function rewindSong():Void {
		gameAudio.stopAll();
		initSong();
	}

	//

	override public function update(elapsed:Float) {
		#if HSCRIPT_ALLOWED
		script.call("onUpdate", [elapsed]);
		#end

		if (gameAudio.inst != null)
			RhythmCore.songPosition = gameAudio.inst.time;

		gameAudio.resyncVocals();

		gameAudio.volumenVocs(SONG, chars.isPlayerMissing(), elapsed);

		cameraController.update(elapsed);

		noteController.update(RhythmCore.songPosition);

		if (playStateConfig.health <= 0)
			isDeath();

		if (SONG.songData.gameplay.events != null) {
			events.updateEvents(RhythmCore.songPosition);
		}

		if (chars != null)
			chars.isSinging(noteController, gameAudio, playStateConfig);

		if (!cameraController.existsCamEvents) {
			var singing = chars.getActiveSingingChar();
			if (singing != null)
				cameraController.followChar = singing;
		}

		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		script.call("postUpdate", [elapsed]);
		#end
	}

	override public function beatHit() {
		super.beatHit();

		if (beat % 4 == 0)
			cameraController.bumpZoom();

		chars.danceAll();
	}

	override public function destroy() {
		FlxG.signals.focusLost.remove(onFocusLost);
		FlxG.signals.focusGained.remove(onFocusGained);

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

		if (events != null)
			events.destroy();
		events = null;

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

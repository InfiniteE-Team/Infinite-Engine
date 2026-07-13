package game;

// camera
import game.objects.Camera;
import game.controllers.CameraController;
// notes
import game.controllers.NoteController;
// visuals
import core.assets.FunkinSprite;
import game.controllers.CharacterController;
import game.controllers.HUDController;
import game.objects.sprites.Stage;
// songs
import core.rhythm.DiffsUtils;
import core.rhythm.RhythmCore;
import core.rhythm.audio.GameAudio;
import core.json.song.SongData.SongConfig;
import game.controllers.events.EventManager;
import game.objects.Countdown;
// window
import windowmodcharting.WindowModManager;

class PlayState extends MusicBeatState {
	public static var instance:PlayState;

	// cameras
	public var camGame:Camera;
	public var camHUD:Camera;
	public var cameraController:CameraController;

	// Song
	public var curSong:String = '4score';

	public static var SONG:SongConfig = new SongConfig();

	public var curDifficulty:Int = 0;

	public var countDown:Countdown;

	// notes
	public var gameAudio:GameAudio = new GameAudio();
	public var events:EventManager = new EventManager();
	public var noteController:NoteController;
	public var modchartSystem:game.modchart.ModchartSystem;
	public var sustainRenderer:game.modchart.SustainRenderer;

	public var windowMod:WindowModManager = null;

	// visuals
	public var chars:CharacterController;
	public var stage:Stage;
	public var controllerHUD:HUDController;

	// configs
	public var playStateConfig:PlayStateConfig = new PlayStateConfig(); // data for health, strum line, etc

	public var osuMode:Bool = false;

	public var paused:Bool = false;

	public var startCount:Bool = false;

	override public function create() {
		instance = this;

		#if HSCRIPT_ALLOWED
		startScript();
		#end

		addCameras();

		#if HSCRIPT_ALLOWED
		script.call("onCreate", []);
		#end

		DiffsUtils.getDifficulty(curSong);

		SONG.configSong(curSong, DiffsUtils.difficulties[curDifficulty]);

		buildStageandChars();

		add(gameAudio);

		FlxG.signals.focusLost.add(onFocusLost);
		FlxG.signals.focusGained.add(onFocusGained);

		controllerHUD = new HUDController();
		controllerHUD.cameras = [camHUD];
		add(controllerHUD);

		buildStrumsandNotes();

		modchartSystem = new game.modchart.ModchartSystem(noteController);
		add(modchartSystem);
		modchartSystem.cacheStrumBase();

		windowMod = new WindowModManager();
		add(windowMod);

		startCountdown();

		super.create();

		#if HSCRIPT_ALLOWED
		core.scripting.ScriptedVars.gameplayVars(script, this);
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
		if (!osuMode)
			add(stage);

		chars = new CharacterController();
		if (!osuMode)
			stage.charLayer.add(chars);

		for (data in SONG.chars) {
			chars.loadCharacter(data.id, data.name, data.role, stage.charLayer, script);
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

		var opponentData = Lambda.find(SONG.chars, c -> CharacterController.namesOpponent.contains(c.role)) ?? (SONG.chars.length > 0 ? SONG.chars[0] : null);
		if (!cameraController.existsCamEvents) {
			if (opponentData != null)
				cameraController.char = cast(chars.get(opponentData.id), game.objects.sprites.Character);
		}

		#if HSCRIPT_ALLOWED
		script.call("postBuildStage", []);
		#end
	}

	function buildStrumsandNotes() {
		noteController = new NoteController(SONG, SaveData.data.downscroll, SaveData.data.ghosttaping, script, playStateConfig, gameAudio);
		core.ConfigMain.controls.loadPreset(noteController.keys);
		for (noteControl in [
			noteController.strums,
			noteController.sustains,
			noteController.notes,
			noteController.splashes
		]) {
			noteControl.cameras = [camHUD];
			add(noteControl);
		}

		// NoteController.meshSustainsActive = true;
	}

	// Code Song
	public function loadSong() {
		gameAudio.loadSong(SONG.needVoices, endSong);

		noteController.generateNotes(0, SONG);

		if (SONG.songData.gameplay.events != null)
			events.loadEvents(SONG.songData.gameplay.events);
	}

	public function startCountdown() {
		startCount = true;

		countDown = new Countdown(0, 0, SONG.countdown);
		countDown.cameras = [camHUD];
		add(countDown);

		countDown.onComplete = function() {
			loadSong();
			initSong();
		}

		if (!countDown.skipCountdown)
			countDown.onCountdown();
		else
			countDown.onComplete();
	}

	public function initSong() {
		startCount = false;

		gameAudio.playAll();

		tracker.reset();
	}

	public function endSong() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onEndSong', []))
			return;
		#end
		// idk what to do here, maybe go to score screen or something? for now just reset the state
		MusicBeatState.resetState();
	}

	// Other screens idk
	public function pauseMenu() {
		if (paused)
			return;

		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onPauseMenuCancel', []))
			return;
		#end

		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		RhythmCore.pause(gameAudio);
		if (windowMod != null)
			windowMod.pauseWindow();

		#if HSCRIPT_ALLOWED
		script.call('onPauseMenu', []);
		#end

		openSubState(new states.substates.PauseMenuSubstate());

		#if HSCRIPT_ALLOWED
		script.call('postPauseMenu', []);
		#end
	}

	public function isDeath() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onDeath', []))
			return;
		#end
		Trace.traceOnce("isDeath is being called! This should be overridden in a subclass if you want to use it.");

		rewindSong();
	}

	override public function closeSubState():Void {
		super.closeSubState();
		paused = false;
		RhythmCore.resume(gameAudio);
		if (windowMod != null)
			windowMod.resumeWindow();
		gameAudio.resyncVocals();
	}

	override function onFocusLost():Void {
		FlxG.sound.pause();
		gameAudio.pauseAll();
		#if HSCRIPT_ALLOWED
		script.call('onFocusLost', []);
		#end
	}

	function onFocusGained():Void {
		#if HSCRIPT_ALLOWED
		script.call('onFocusGained', []);
		#end
		FlxG.sound.resume();
		if (!paused) {
			gameAudio.playAll();
			gameAudio.resyncVocals();
		}
		#if HSCRIPT_ALLOWED
		script.call('postFocusGained', []);
		#end
	}

	function startScript() {
		initScript();
		script.loadFolder('songs/$curSong/scripts');
		script.load(Paths.getPath('hud', 'script'));
		script.executeAll();
	}

	public function rewindSong():Void {
		#if HSCRIPT_ALLOWED
		if (script != null) {
			script.call("onDestroy", []);
			script.destroy();
			script = null;
		}
		startScript();
		#end

		gameAudio.stopAll();

		if (noteController != null) {
			remove(noteController.strums);
			remove(noteController.sustains);
			remove(noteController.notes);
			remove(noteController.splashes);

			noteController.destroy();
			noteController = null;
		}

		if (events != null) {
			events.destroy();
			events = new EventManager();
		}

		playStateConfig = new PlayStateConfig();

		RhythmCore.reset(SONG.bpmSong);

		if (chars != null)
			chars.danceAll();

		if (modchartSystem != null) {
			modchartSystem.clearAll();
		}

		if (sustainRenderer != null) {
			sustainRenderer.destroy();
			sustainRenderer = null;
		}

		buildStrumsandNotes();
		startCountdown();

		#if HSCRIPT_ALLOWED
		script.call('onRewind', []);
		#end
	}

	//

	override public function update(elapsed:Float) {
		#if HSCRIPT_ALLOWED
		script.call("onUpdate", [elapsed]);
		#end

		if (gameAudio.inst != null)
			RhythmCore.songPosition = gameAudio.inst.time;

		gameAudio.volumenVocs(SONG, chars.isPlayerMissing(), elapsed);

		if (!paused || !startCount) {
			cameraController.update(elapsed);

			noteController.update(RhythmCore.songPosition);

			if (playStateConfig.health <= 0)
				isDeath();

			if (SONG.songData.gameplay.events != null) {
				events.updateEvents(RhythmCore.songPosition);
			}

			if (!osuMode || chars != null)
				chars.isSinging(noteController);

			if (chars != null)
				chars.processInput(noteController, gameAudio, playStateConfig);

			if (!osuMode) {
				if (!cameraController.existsCamEvents) {
					var singing = chars.getActiveSingingChar();
					if (singing != null)
						cameraController.char = singing;
				}
			}
		}

		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		script.call("postUpdate", [elapsed]);
		#end
	}

	override public function stepHit(step:Int) {
		super.stepHit(step);
	}

	override public function beatHit(beat:Float) {
		super.beatHit(beat);

		if (beat % 4 == 0)
			cameraController.bumpZoom();

		controllerHUD.beatHit(beat);

		if (!osuMode || !paused)
			chars.danceAll();

		#if HSCRIPT_ALLOWED
		script.call('postBeatHit', [beat]);
		#end
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

		if (modchartSystem != null) {
			modchartSystem.destroy();
			modchartSystem = null;
		}

		if (sustainRenderer != null) {
			sustainRenderer.destroy();
			sustainRenderer = null;
		}

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

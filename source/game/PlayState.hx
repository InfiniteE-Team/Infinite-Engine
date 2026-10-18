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

// import windowmodcharting.WindowModManager;
class PlayState extends MusicBeatState {
	public static var instance:PlayState;

	// cameras
	public var camGame:Camera;
	public var camHUD:Camera;
	public var camOther:Camera;
	public var camSubtitles:Camera;

	public var cameraController:CameraController;

	public var subtitleManager:game.objects.Subtitle;

	// Song
	public var curSong:String = 'default';

	public static var SONG:SongConfig;

	public var curDifficulty:Int = 0;

	public var countDown:Countdown;

	// notes
	public var gameAudio:GameAudio;
	public var events:EventManager;
	public var noteController:NoteController;
	public var modchartSystem:game.modchart.ModchartSystem;

	// public var windowMod:WindowModManager = null;
	// visuals
	public var chars:CharacterController;
	public var stage:Stage;
	public var controllerHUD:HUDController;

	// configs
	public var playStateConfig:PlayStateConfig; // data for health, strum line, etc

	public var osuMode:Bool = false;

	public var paused:Bool = false;
	public var isRewind:Bool = false;

	public var startCount:Bool = false;

	public var startTime:Float = 0;

	public function new(?curSong:String, ?curDifficulty:Int = 0) {
		super();
		gameAudio = new GameAudio();
		events = new EventManager();
		playStateConfig = new PlayStateConfig();
		this.curSong = curSong;
		this.curDifficulty = curDifficulty;
	}

	override public function create() {
		instance = this;

		if (FlxG.mouse != null)
			FlxG.mouse.visible = false;

		PlayStateConfig.isPlaying = true;

		if (playStateConfig != null)
			playStateConfig.reset();

		addCameras();

		SONG = new SongConfig();
		SONG.configSong(curSong, DiffsUtils.difficulties[curDifficulty]);

		modding.vslice.VSliceHooks.reset();
		funkin.play.PlayState.instance = modding.vslice.VSlice.isActive() ? new funkin.play.PlayState(null, curSong) : null;

		#if HSCRIPT_ALLOWED
		startScript();
		script.call("onCreate", []);
		#end

		#if DISCORD_ALLOWED
		core.api.DiscordAPI.instance.setPresence({
			details: 'Playing: ${curSong}',
			state: 'Difficulty: ' + DiffsUtils.difficulties[curDifficulty].toUpperCase(),
			largeImageKey: "album-volume1"
		});
		#end

		titleGameplay();

		buildStageandChars();

		add(gameAudio);

		controllerHUD = new HUDController(script);
		controllerHUD.cameras = [camHUD];
		add(controllerHUD);

		subtitleManager = new game.objects.Subtitle();
		subtitleManager.cameras = [camSubtitles];
		add(subtitleManager);

		super.create();

		RhythmCore.reset(SONG.bpmSong);
		t.reset();

		buildStrumsandNotes();
		/*
			windowMod = new WindowModManager();
			add(windowMod); */

		loadSong();

		startCountdown();

		#if HSCRIPT_ALLOWED
		modding.scripting.ScriptedVars.gameplayVars(script, this);
		script.call("postCreate", []);
		#end
	}

	function titleGameplay() {
		var titleName:String = modding.mods.ModData.ModConfig.modData?.name;
		if (modding.mods.ModData.ModConfig.modData?.name == null)
			titleName = "Infinite Engine";

		lime.app.Application.current.window.title = titleName + " - Song: " + curSong;
	}

	public function addCameras() {
		camGame = new Camera();
		camHUD = new Camera();
		camHUD.bgColor.alpha = 0;

		camOther = new Camera();
		camOther.bgColor.alpha = 0;

		camSubtitles = new Camera();
		camSubtitles.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camSubtitles, false);

		cameraController = new CameraController(camGame, camHUD);
	}

	public function buildStageandChars() {
		#if HSCRIPT_ALLOWED
		script.call("buildStage", []);
		#end

		stage = new Stage(SONG.stage);
		cameraController.defaultZoom = stage.defaultZoom;
		cameraController.stageZoom = stage.defaultZoom;
		if (!osuMode)
			add(stage);

		chars = new CharacterController();
		if (!osuMode)
			stage.charLayer.add(chars);

		for (data in SONG.chars) {
			chars.loadCharacter(data.id, data.name, data.role, stage.charLayer, script);
			applyStageProps(cast(chars.get(data.id), game.objects.sprites.Character), data.id);
		}

		var opponentData = Lambda.find(SONG.chars, c -> CharacterController.namesOpponent.contains(c.role)) ?? (SONG.chars.length > 0 ? SONG.chars[0] : null);
		if (!cameraController.existsCamEvents) {
			if (opponentData != null)
				cameraController.char = cast(chars.get(opponentData.id), game.objects.sprites.Character);
		}

		loadVSliceSong();

		#if HSCRIPT_ALLOWED
		script.call("postBuildStage", []);
		#end
	}

	function loadVSliceSong():Void {
		if (funkin.play.PlayState.instance == null)
			return;
		var song = modding.vslice.VSliceScripts.loadSongScript(curSong);
		if (song == null)
			return;
		funkin.play.PlayState.instance.currentSongScript = song;
		modding.vslice.VSliceHooks.register(song);
		modding.vslice.VSliceHooks.call(song, 'onCreate', modding.vslice.VSliceHooks.event('CREATE'));
	}

	// reapply stage pos + camPos, Change Character resets them -JloorDev
	public function applyStageProps(char:game.objects.sprites.Character, id:String):Void {
		if (char == null || stage == null)
			return;
		stage.applyCharProps(char, id);
		var stageProps = stage.charProps.get(id);
		if (stageProps?.camPos != null) {
			char.cameraOffset.x += stageProps.camPos[0];
			char.cameraOffset.y += stageProps.camPos[1];
		}
	}

	function buildStrumsandNotes() {
		noteController = new NoteController(SONG, SaveData.data.downscroll, SaveData.data.ghosttaping, script, playStateConfig, gameAudio);
		noteController.charController = chars;
		core.ConfigMain.controls.loadPreset(noteController.keys);
		for (noteControl in [
			noteController.blackBacks,
			noteController.strums,
			noteController.sustains,
			noteController.notes,
			noteController.splashes,
			noteController.holdsplashes
		]) {
			noteControl.cameras = [camHUD];
			add(noteControl);
		}

		chars.initControllers(noteController, gameAudio, playStateConfig);

		modchartSystem = new game.modchart.ModchartSystem(noteController);
		add(modchartSystem);
		modchartSystem.cacheStrumBase();
	}

	// Code Song
	public function loadSong() {
		if (SONG == null || SONG.songData == null)
			return;

		gameAudio.loadSong(SONG, SONG.needVoices, endSong);
		gameAudio.pauseAll();
		RhythmCore.pause(gameAudio);

		if (startTime > 0)
			gameAudio.setTime(startTime);

		noteController.generateNotes(startTime, SONG);

		if (SONG.songData.gameplay.events != null) {
			events.loadEvents(SONG.songData.gameplay.events);
			events.updateEvents(0);
		}
		modding.vslice.VSliceHooks.dispatch('onSongLoaded', modding.vslice.VSliceHooks.event('SONG_LOADED'));
	}

	var vsliceCountdownHeld:Bool = false;
	var skipVSliceCountdown:Bool = false;
	var vsliceHeldTime:Float = 0;
	var vsliceHeldFailures:Int = 0;

	public function resumeVSliceCountdown(force:Bool = false):Void {
		if (!vsliceCountdownHeld)
			return;
		vsliceCountdownHeld = false;
		startCountdown(force);
	}

	public function startCountdown(skipVSlice:Bool = false) {
		isRewind = false;
		var countdownEvent = modding.vslice.VSliceHooks.event('COUNTDOWN_START');
		if (!skipVSlice)
			modding.vslice.VSliceHooks.dispatch('onCountdownStart', countdownEvent);
		if (countdownEvent.eventCanceled == true && funkin.play.PlayState.instance?.isInCountdown == true) {
			countdownEvent.eventCanceled = false;
			skipVSliceCountdown = true;
		}
		if (countdownEvent.eventCanceled == true) {
			vsliceCountdownHeld = true;
			vsliceHeldTime = 0;
			vsliceHeldFailures = modding.vslice.VSliceHooks.failures;
			return;
		}
		if (funkin.play.PlayState.instance != null)
			funkin.play.PlayState.instance.isInCountdown = true;
		#if HSCRIPT_ALLOWED
		script.call("onCountdown", []);
		#end
		startCount = true;

		var crochet:Float = (60 / SONG.bpmSong) * 1000;
		RhythmCore.songPosition = startTime > 0 ? startTime : -crochet * 4;

		countDown = new Countdown(0, 0, SONG.countdown);
		countDown.cameras = [camOther];
		countDown.onComplete = initSong;

		if (startTime > 0) {
			countDown.onComplete();
			return;
		}

		add(countDown);

		var skipThis = countDown.skipCountdown || skipVSliceCountdown;
		skipVSliceCountdown = false;
		if (!skipThis) {
			countDown.onCountdown();
			if (chars != null)
				chars.danceAll();
		} else {
			RhythmCore.songPosition = 0;
			countDown.onComplete();
		}
	}

	public function initSong() {
		startCount = false;

		if (startTime > 0) {
			gameAudio.setTime(startTime);
			RhythmCore.songPosition = startTime;
		}

		gameAudio.playAll();
		RhythmCore.resume(gameAudio);
		if (funkin.play.PlayState.instance != null)
			funkin.play.PlayState.instance.isInCountdown = false;
		modding.vslice.VSliceHooks.dispatch('onCountdownEnd', modding.vslice.VSliceHooks.event('COUNTDOWN_END'));
		modding.vslice.VSliceHooks.dispatch('onSongStart', modding.vslice.VSliceHooks.event('SONG_STARTED'));
		#if HSCRIPT_ALLOWED
		script.call("postInitSong", []);
		#end
	}

	var _endSongCalled:Bool = false;

	public function endSong() {
		if (_endSongCalled)
			return;
		_endSongCalled = true;

		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onEndSongCancel', []))
			return;
		#end

		modding.vslice.VSliceHooks.dispatch('onSongEnd', modding.vslice.VSliceHooks.event('SONG_END'));

		cameraController.char = null;
		var opp = cast(chars.get(Lambda.find(SONG.chars, c -> CharacterController.namesOpponent.contains(c.role))?.id), game.objects.sprites.Character);
		var ply = cast(chars.get(Lambda.find(SONG.chars, c -> !CharacterController.namesOpponent.contains(c.role))?.id), game.objects.sprites.Character);

		if (opp != null && ply != null)
			cameraController.centerCamera(opp, ply, true);
		else
			cameraController.isLock = true;

		flixel.tweens.FlxTween.tween(cameraController.camPoint, {y: cameraController.camPoint.y - 200}, 1, {ease: flixel.tweens.FlxEase.quadOut});

		if (!PlayStateConfig.isStoryMode) {
			core.config.SaveScore.saveSong(curSong, playStateConfig.score, curDifficulty);
			new flixel.util.FlxTimer().start(0.9, (_) -> {
				modding.scripting.types.ScriptClass.switchState('ResultScreen', [playStateConfig]);
			});
		} else {
			PlayStateConfig.storyScore += playStateConfig.score;
			if (PlayStateConfig.storyPlaylist.length > 0) {
				var nextSong = PlayStateConfig.storyPlaylist[0];
				PlayStateConfig.storyPlaylist.shift();
				new flixel.util.FlxTimer().start(0.9, (_) -> {
					MusicBeatState.switchState(() -> new states.LoadingState(nextSong, curDifficulty));
				});
			} else {
				core.config.SaveScore.saveWeek(PlayStateConfig.storyWeekName, PlayStateConfig.storyScore, curDifficulty);
				new flixel.util.FlxTimer().start(0.9, (_) -> {
					PlayStateConfig.isStoryMode = false;
					PlayStateConfig.storyScore = 0;
					modding.scripting.types.ScriptClass.switchState('ResultScreen', [playStateConfig]);
				});
			}
		}

		#if HSCRIPT_ALLOWED
		script.call('postEndSong', []);
		#end

		PlayStateConfig.blueBalled = 0;
	}

	// Other screens idk
	public function pauseMenu() {
		if (paused)
			return;

		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onPauseCancel', []))
			return;
		#end

		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		countDown.pause();

		FlxG.sound.pause();
		gameAudio.pauseAll();
		RhythmCore.pause(gameAudio);
		/*
			if (windowMod != null)
				windowMod.pauseWindow(); */

		#if HSCRIPT_ALLOWED
		script.call('onPause', []);
		#end
		modding.vslice.VSliceHooks.dispatch('onPause', modding.vslice.VSliceHooks.event('PAUSE'));
		events?.videos.pause();

		flixel.tweens.FlxTween.globalManager.forEach((tween:flixel.tweens.FlxTween) -> {
			if (tween.active) {
				tween.active = false;
			}
		});

		openSubState(new states.substates.menus.PauseMenuSubstate());

		#if HSCRIPT_ALLOWED
		script.call('postPauseMenu', []);
		#end
	}

	public function isDeath() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onDeath', []))
			return;
		#end

		PlayStateConfig.blueBalled++;
		modding.vslice.VSliceHooks.dispatch('onGameOver', modding.vslice.VSliceHooks.event('GAME_OVER'));
		events?.videos.pause();

		persistentUpdate = false;
		persistentDraw = false;
		paused = true;

		FlxG.sound.music?.stop();
		if (gameAudio != null)
			gameAudio.stopAll();
		RhythmCore.pause(gameAudio);

		openSubState(new states.substates.GameOverSubstate());
	}

	override public function closeSubState():Void {
		super.closeSubState();
		paused = false;
		RhythmCore.resume(gameAudio);

		#if HSCRIPT_ALLOWED
		script.call('onResume', []);
		#end
		modding.vslice.VSliceHooks.dispatch('onResume', modding.vslice.VSliceHooks.event('RESUME'));
		events?.videos.resume();

		flixel.tweens.FlxTween.globalManager.forEach((tween:flixel.tweens.FlxTween) -> {
			if (!tween.active) {
				tween.active = true;
			}
		});

		/*
			if (windowMod != null)
				windowMod.resumeWindow(); */
		gameAudio.resyncVocals();
	}

	override function onFocusLost():Void {
		#if HSCRIPT_ALLOWED
		script.call('onFocusLost', []);
		#end
		pauseMenu();
	}

	override function onFocus():Void {
		#if HSCRIPT_ALLOWED
		script.call('onFocus', []);
		#end

		#if HSCRIPT_ALLOWED
		script.call('postFocus', []);
		#end
	}

	function startScript() {
		initScript();
		script.loadFolder('songs/$curSong/scripts');
		script.loadFolder('scripts/gameplay');
		script.executeAll();
	}

	public function rewindSong():Void {
		#if HSCRIPT_ALLOWED
		if (script != null) {
			script.call("onDestroy", []);
			script.destroy();
			script = null;
		}
		#end

		isRewind = true;

		modding.vslice.VSliceHooks.dispatch('onSongRetry', modding.vslice.VSliceHooks.event('SONG_RETRY'));
		if (chars != null)
			for (c in chars.registry)
				if (Std.isOfType(c, game.objects.sprites.Character) && cast(c, game.objects.sprites.Character).vslice != null)
					modding.vslice.VSliceHooks.call(cast(c, game.objects.sprites.Character).vslice, 'resetCharacter', true);

		game.graphics.shaders.CustomShader.clearAll();

		gameAudio.stopAll();

		if (modchartSystem != null) {
			modchartSystem.destroy();
		}

		if (noteController != null) {
			for (noteControl in [
				noteController.blackBacks,
				noteController.strums,
				noteController.sustains,
				noteController.notes,
				noteController.splashes,
				noteController.holdsplashes
			]) {
				if (noteControl != null)
					remove(noteControl);
			}
			noteController.destroy();
			noteController = null;
		}

		if (events != null) {
			events.destroy();
			events = new EventManager();
		}

		RhythmCore.reset(SONG.bpmSong);
		t.reset(); // reset steps and beats

		if (playStateConfig != null)
			playStateConfig.reset();

		#if HSCRIPT_ALLOWED
		startScript();
		script.call("onCreate", []);
		#end

		if (controllerHUD != null) {
			controllerHUD.destroy();
			controllerHUD = null;
			controllerHUD = new HUDController(script);
			controllerHUD.cameras = [camHUD];
			add(controllerHUD);
		}

		if (countDown != null) {
			countDown.pause();
			remove(countDown);
			countDown.destroy();
			countDown = null;
		}

		buildStrumsandNotes();

		noteController.generateNotes(0, SONG);
		startCountdown();

		if (chars != null)
			chars.resetAll();

		if (SONG.songData.gameplay.events != null) {
			events.loadEvents(SONG.songData.gameplay.events);
			events.updateEvents(0);
		}

		#if HSCRIPT_ALLOWED
		modding.scripting.ScriptedVars.gameplayVars(script, this);
		script.call("postCreate", []);
		#end

		flixel.tweens.FlxTween.cancelTweensOf(cameraController);

		#if HSCRIPT_ALLOWED
		script.call('onRewindPost', []);
		#end
	}

	override public function update(elapsed:Float) {
		#if HSCRIPT_ALLOWED
		if (script != null && script.hasScripts)
			script.call("onUpdate", [elapsed]);
		#end

		super.update(elapsed);

		if (!paused)
			modding.vslice.VSliceHooks.dispatch('onUpdate', modding.vslice.VSliceHooks.event('UPDATE', {elapsed: elapsed}));

		if (vsliceCountdownHeld && !paused) {
			vsliceHeldTime += elapsed;
			if (modding.vslice.VSliceHooks.failures > vsliceHeldFailures || vsliceHeldTime > 60) {
				Console.log('[V-Slice] the song script held the countdown and its cutscene did not finish, starting the song', true);
				if (camHUD != null) {
					camHUD.visible = true;
					camHUD.alpha = 1;
				}
				if (funkin.play.PlayState.instance != null)
					funkin.play.PlayState.instance.isInCutscene = false;
				resumeVSliceCountdown(true);
			}
		}

		if (FlxG.keys.justPressed.SEVEN && core.ConfigMain.globalData.developerMode) {
			modding.editors.GameplayEditor.SONG = SONG;
			// instance is null when the editor opens, so I pass folder and diff here -JloorDev
			modding.editors.GameplayEditor.folder = curSong;
			modding.editors.GameplayEditor.diff = DiffsUtils.difficulties[curDifficulty];
			MusicBeatState.switchState(() -> new modding.editors.GameplayEditor());
		}

		if (!paused) {
			RhythmCore.songPosition += elapsed * 1000;
			if (!startCount && gameAudio != null && gameAudio.inst != null && gameAudio.inst.playing)
				RhythmCore.songPosition = gameAudio.inst.time;
		}

		if (gameAudio != null && chars != null && SONG != null)
			gameAudio.volumenVocs(SONG, chars.isPlayerMissing(), elapsed);

		if (!paused) {
			if (cameraController != null)
				cameraController.update(elapsed);

			if (noteController != null)
				noteController.update(RhythmCore.songPosition);

			if (playStateConfig != null && playStateConfig.health <= 0)
				isDeath();

			if (SONG != null && SONG.songData != null && SONG.songData.gameplay != null && SONG.songData.gameplay.events != null) {
				if (events != null)
					events.updateEvents(RhythmCore.songPosition);
			}

			if (chars != null) {
				if (!osuMode)
					chars.isSinging(noteController);

				chars.processInput(noteController, gameAudio, playStateConfig);

				if (!osuMode && cameraController != null) {
					if (!cameraController.existsCamEvents) {
						var singing = chars.getActiveSingingChar();
						if (singing != null)
							cameraController.char = singing;
					}
				}
			}
		}

		if (Controls.ACCEPT)
			pauseMenu();

		if (Controls.GAME_DEATH && !startCount)
			isDeath();

		#if HSCRIPT_ALLOWED
		if (script != null && script.hasScripts)
			script.call("postUpdate", [elapsed]);
		#end
	}

	override public function stepHit(step:Int) {
		super.stepHit(step);

		gameAudio.resyncVocals();
		modding.vslice.VSliceHooks.dispatch('onStepHit', modding.vslice.VSliceHooks.event('SONG_STEP_HIT', {step: step}));
		funkin.Conductor.stepHit.dispatch();

		#if HSCRIPT_ALLOWED
		if (stage != null)
			stage.onStepHit(step);
		#end
	}

	override public function beatHit(beat:Float) {
		super.beatHit(beat);

		if (cameraController.bopEvery > 0 && beat % cameraController.bopEvery == 0)
			cameraController.bumpZoom();

		if (controllerHUD != null)
			controllerHUD.beatHit(beat);

		if (!osuMode || !paused)
			chars.danceAll();

		if (stage != null)
			stage.onBeatHit(beat);
		modding.vslice.VSliceHooks.dispatch('onBeatHit', modding.vslice.VSliceHooks.event('SONG_BEAT_HIT', {beat: Std.int(beat), step: Std.int(beat * 4)}));
		funkin.Conductor.beatHit.dispatch();

		#if HSCRIPT_ALLOWED
		script.call('postBeatHit', [beat]);
		#end
	}

	override public function destroy() {
		PlayStateConfig.isPlaying = false;

		var songScript = funkin.play.PlayState.instance?.currentSongScript;
		if (songScript != null)
			modding.vslice.VSliceHooks.call(songScript, 'onDestroy', modding.vslice.VSliceHooks.event('DESTROY'));

		if (FlxG.mouse != null)
			FlxG.mouse.visible = true;

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

		if (countDown != null)
			countDown.destroy();

		if (modchartSystem != null) {
			modchartSystem.destroy();
			modchartSystem = null;
		}

		if (noteController != null)
			noteController.destroy();

		if (events != null)
			events.destroy();

		if (cameraController != null) {
			flixel.tweens.FlxTween.cancelTweensOf(cameraController);
		}

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

		lime.app.Application.current.window.title = modding.mods.ModData.ModConfig.modData?.name ?? "Infinite Engine";

		game.graphics.shaders.CustomShader.clearAll();

		super.destroy();
		modding.vslice.VSliceHooks.reset();
		funkin.play.PlayState.instance = null;
	}
}

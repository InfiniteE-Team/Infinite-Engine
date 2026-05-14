package game;

// camera
import game.objects.Camera;
// notes
import game.controllers.NoteController;
// visuals
import core.assets.FunkinSprite;
import game.controllers.CharacterController;
// songs
import core.rhythm.RhythmCore;
import core.rhythm.audio.GameAudio;
import core.json.song.SongData.SongConfig;
// saves
import core.config.SaveData;

class PlayState extends MusicBeatState {
	public static var instance:PlayState;
	
	public var isStoryMode:Bool = false;

	public var chars:CharacterController;
	// cameras
	public var camGame:Camera;
	public var camHUD:Camera;

	// Song
	public static var SONG:SongConfig = new SongConfig();

	public var gameAudio:GameAudio = new GameAudio();
	public var curSong:String = 'fresh';

	public var noteController:NoteController;

	// configs
	public var saveData:SaveData = new SaveData();

	override public function create() {
		instance = this;
		FlxG.mouse.visible = false;

		addCameras();

		SONG.configSong(curSong, '');

		addCharacters();

		initSong();

		FlxG.signals.focusLost.add(onFocusLost);
		FlxG.signals.focusGained.add(onFocusGained);

		super.create();
	}

	public function addCharacters() {
		chars = new CharacterController('id_');
		add(chars);
		for (data in SONG.chars) {
			chars.loadCharacter(data.id, data.name, data.role);
		}
	}

	public function addCameras() {
		camGame = new Camera();
		camHUD = new Camera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
	}

	function buildStrumsandNotes()
	{
		noteController = new NoteController(SONG,saveData.downscroll);
		noteController.strums.cameras = [camHUD];
		noteController.notes.cameras = [camHUD];
		add(noteController.strums);
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
		super.update(elapsed);
		if (gameAudio.inst != null)
			RhythmCore.songPosition = gameAudio.inst.time;

		gameAudio.resyncVocals();

		noteController.update(RhythmCore.songPosition);

		if (chars != null)
			chars.isSinging(noteController,SONG.noteLane);
	}

	override public function beatHit() {
		super.beatHit();

		for (data in SONG.chars) {
			chars.get(data.id).dance();
		}
	}

	override public function destroy() {
        FlxG.signals.focusLost.remove(onFocusLost);
        FlxG.signals.focusGained.remove(onFocusGained);

		FunkinSprite.clearCache();
		camGame.destroy();
		camHUD.destroy();
		gameAudio.destroy();
		chars.destroy();

		noteController.destroy();

		instance = null;
		chars = null;
		gameAudio = null;

		// cameras
		camGame = null;
		camHUD = null;

		noteController = null;

        super.destroy();
	}
}

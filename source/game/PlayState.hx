package game;

// camera
import game.objects.Camera;
// notes
import game.objects.sprites.StrumNote;
// visuals
import core.assets.FunkinSprite;
import game.controllers.CharacterController;
// songs
import core.rhythm.RhythmCore;
import core.rhythm.audio.GameAudio;
import core.json.song.SongData.SongConfig;

class PlayState extends MusicBeatState {
	public static var instance:PlayState;
	public var chars:CharacterController;

    public var camGame:Camera;

    // Song
    public static var SONG:SongConfig = new SongConfig();
    public var gameAudio:GameAudio = new GameAudio();
    public var curSong:String = 'fresh';

	override public function create() {
		instance = this;
        FlxG.mouse.visible = false;
        camGame = new Camera();
        FlxG.cameras.reset(camGame);
        @:privateAccess flixel.FlxCamera._defaultCameras = [camGame];

        //camGame.zoom = 0.9;

        SONG.configSong(curSong,'');

        addCharacters();

        initSong();

		super.create();
	}

    public function addCharacters()
    {
        chars = new CharacterController('id_');
        add(chars);
        for (data in SONG.chars) {
            chars.loadCharacter(data.id, data.name);
        }
    }

    // Code Song
    public function initSong()
    {
        gameAudio.loadSong(SONG.needVoices,endSong);
        gameAudio.playAll();
    }

    public function startCountdown()
    {
        
    }

    public function endSong()
    {

    }

    // Other screens idk
    public function pauseMenu()
    {

    }

    public function isDeath()
    {

    }

    // 

	override public function update(elapsed:Float) {
		super.update(elapsed);
        if (gameAudio.inst != null)
            RhythmCore.songPosition = gameAudio.inst.time;

        if (chars != null)
            chars.isSinging();

        
        gameAudio.resyncVocals();
	}

	override public function beatHit() {
		super.beatHit();

        
		for (data in SONG.chars) {
			chars.get(data.id).dance();
		}
	}

    override public function destroy()
    {
        super.destroy();

        FunkinSprite.clearCache();
        camGame.destroy();
        gameAudio.destroy();
        chars.destroy();

        instance = null;
        chars = null;
        gameAudio = null;
        camGame = null;
    }
}
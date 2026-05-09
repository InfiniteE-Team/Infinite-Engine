package game;

import game.objects.Camera;
import core.json.song.SongData.SongConfig;
import game.objects.sprites.StrumNote;
import game.controllers.CharacterController;

class PlayState extends MusicBeatState {
    public static var SONG:SongConfig;
	public static var instance:PlayState;
	public var chars:CharacterController;
    public var curSong:String = 'fresh';

    public var camGame:Camera;

	override public function create() {
		instance = this;
        camGame = new Camera();
        FlxG.cameras.reset(camGame);
        @:privateAccess flixel.FlxCamera._defaultCameras = [camGame];

        if (SONG == null) SONG = new SongConfig();
        SONG.configSong(curSong,'');

        addCharacters();

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

	override public function update(elapsed:Float) {
		super.update(elapsed);

        if (chars != null)
            chars.isSinging();
	}

	override public function beatHit() {
		super.beatHit();

		for (data in SONG.chars) {
			chars.get(data.id).dance();
		}
	}
}
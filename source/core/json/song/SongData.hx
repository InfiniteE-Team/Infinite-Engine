package core.json.song;

import utils.UtilsData;
import core.rhythm.RhythmCore;
typedef SongData = {
	var meta:MetaData;
	var gameplay:GameplayData;
	var notes:Array<NoteData>;
}

typedef MetaData = {
	var song:String;
	var bpm:Float;
	var speed:Float;
    var ?needVoices:Bool;
}

typedef GameplayData = {
	var chars:Array<CharDataJson>;
	var events:Array<EventsData>;
}

typedef CharDataJson = {
	var id:String;
	var name:String;
	var role:String;
}

typedef EventsData = {
	var arguments:Dynamic;
	var time:Float;
	var name:String;
}

// note data
typedef NoteData = {
    var char:Int;
	var lane:Int;
	var time:Float;
	var type:String;
	var length:Float;
}

class SongConfig {
	public var songData:SongData;

	public var songName:String = 'tutorial';
	public var bpmSong:Float = 100;
	public var speed:Float = 1.2;
    public var chars:Array<Dynamic> = [];

    public function new() {}

	public function configSong(curSong:String, diff:String) {
		songData = UtilsData.readJson(Paths.getPath('songs/$curSong/charts/$curSong$diff', 'json'));
		if (songData == null)
			return;
        songName = songData.meta.song;
		bpmSong = songData.meta.bpm;
		speed = songData.meta.speed;

        RhythmCore.bpm = bpmSong;

        chars = songData.gameplay.chars;
	}
}

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
	var ?vocSeparated:Bool;
}

typedef GameplayData = {
	var chars:Array<CharDataJson>;
	var events:Array<EventsData>;
}

typedef CharDataJson = {
	var id:String;

	var ?name:String;
	var ?role:String;

	var ?position:Array<Float>;
	var ?camPos:Array<Float>;

	var ?vocals:String;
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

	public var songName:String = 'Fresh';
	public var bpmSong:Float = 120;
	public var speed:Float = 1.2;
	public var needVoices:Bool = true;

    public var chars:Array<Dynamic> = [];

    public function new() {}

	public function configSong(curSong:String, diff:String) {
		songData = UtilsData.readJson(Paths.getPath('songs/$curSong/charts/$curSong$diff', 'json'));
		if (songData == null)
			return;

        songName = songData.meta.song ?? 'Fresh';
		bpmSong = songData.meta.bpm ?? 120;
		speed = songData.meta.speed ?? 1.2;
		needVoices = songData.meta.needVoices ?? true;

        RhythmCore.changeBPM(bpmSong);

        chars = songData.gameplay.chars;
	}
}

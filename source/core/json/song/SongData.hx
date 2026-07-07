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
	var ?stage:String;
	var ?needVoices:Bool;
	var ?vocSeparated:Bool;
}

typedef GameplayData = {
	var chars:Array<CharDataJson>;
	var events:Array<EventsData>;
}

typedef CharDataJson = {
	// general
	var id:String;
	var ?name:String;
	var ?role:String;

	// song
	var ?vocals:String;

	// strums song
	var ?strumPos:Array<Float>;
	var ?strumScale:Array<Float>;

	// stages
	var ?position:Array<Float>;
	var ?camPos:Array<Float>;

	var ?noteSkin:String;

	var ?strumsVisible:Bool;
}

typedef EventsData = {
	var arguments:Dynamic;
	var time:Float;
	var name:String;
}

// note data
typedef NoteData = {
	var char:String;
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
	public var stage:String = 'stage';

	public var chars:Array<CharDataJson> = [];

	public var noteLane:Int = 0;

	public var noteSkin:String = 'default';

	public var noteTime:Float = 0;

	public var strumsVisible:Bool = true;

	public var vocSeparated:Bool = false;

	public function new() {}

	public function configSong(curSong:String, diff:String) {
		var osuPath:String = null;
		var baseFile = 'songs/$curSong/charts/$curSong$diff';
		for (lib in ['assets', 'engine']) {
			var candidate = '$lib/$baseFile.osu';
			if (sys.FileSystem.exists(candidate)) {
				osuPath = candidate;
				break;
			}
		}

		if (osuPath != null) {
			songData = ChartPorter.tryConvertOsu(osuPath);
			//game.PlayState.instance.osuMode = true;

			Trace.traceOnce('SongData: load Song path: $osuPath');
		}

		if (songData == null) {
			var raw:Dynamic = UtilsData.readJson(Paths.getPath(baseFile, 'json'));
			if (raw == null)
				return;
			var converted = ChartPorter.tryConvert(raw);
			songData = converted ?? cast raw;

			Trace.traceOnce('SongData: load Song path: $baseFile');
		}

		if (songData == null)
			return;

		songName = songData.meta.song ?? 'Fresh';
		bpmSong = songData.meta.bpm ?? 120;
		speed = songData.meta.speed ?? 1.2;
		needVoices = songData.meta.needVoices ?? true;
		stage = songData.meta.stage ?? 'stage';
		vocSeparated = songData.meta.vocSeparated ?? false;

		for (note in songData.notes) {
			noteLane = note.lane ?? 0;
			noteTime = note.time ?? 0;
		}

		RhythmCore.changeBPM(bpmSong);

		chars = songData.gameplay.chars;

		for (i in 0...chars.length) {
			noteSkin = chars[i].noteSkin ?? 'default';
			strumsVisible = chars[i].strumsVisible ?? true;
		}
	}
}

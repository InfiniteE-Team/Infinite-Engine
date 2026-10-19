package core.json.song;

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
	var ?countdown:String;
	var ?needVoices:Bool;
	var ?instPrefix:Null<String>;
	var ?vocPrefix:Null<String>;
	var ?vocs:Null<Array<String>>;
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

	// stages
	var ?position:Array<Float>;
	var ?camPos:Array<Float>;

	// strums song
	var strums:StrumsData;
}

typedef StrumsData = {
	var ?noteSkin:String;
	var ?position:Array<Float>;
	var ?scale:Array<Float>;
	var ?visible:Bool;
	var ?notesVisible:Bool;
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
	public var countdown:String = 'default';

	public var chars:Array<CharDataJson> = [];

	public var noteLane:Int = 0;

	public var noteSkin:String = 'default';

	public var noteTime:Float = 0;

	public var strumsVisible:Bool = true;

	public var instPrefix:String = '';
	public var vocPrefix:String = '';

	public var vocs:Array<String> = [];

	public function new() {}

	public function configSong(songFolder:String, diff:String) {
		var osuPath:String = null;
		var baseFile = 'songs/$songFolder/charts/$diff';
		for (lib in ['assets', 'mods']) {
			var candidate = '$lib/$baseFile.osu';
			if (sys.FileSystem.exists(candidate)) {
				osuPath = candidate;
				break;
			}
		}

		if (osuPath != null) {
			songData = ChartPorter.tryConvertOsu(osuPath);
			Console.log('SongData: load Song path: $osuPath');
		}

		if (songData == null) {
			var raw:Dynamic = FormatJson.readJson(Paths.getPath(baseFile, 'json'));
			var meta:Dynamic = null;
			if (raw == null && modding.vslice.VSlice.isActive()) {
				raw = modding.vslice.VSliceSongs.chart(songFolder);
				meta = modding.vslice.VSliceSongs.metadata(songFolder);
			}
			if (raw == null)
				return;

			loadSeparateMeta(raw, songFolder);

			if (meta == null)
				meta = tryLoadVSliceMeta(songFolder);
			var converted = ChartPorter.tryConvert(raw, diff, meta);
			songData = converted ?? cast raw;

			trace('SongData: load Song path: $baseFile');
		}

		if (songData == null)
			return;

		loadSeparateEvents(songFolder);

		songName = songData.meta.song ?? 'Fresh';
		bpmSong = songData.meta.bpm ?? 120;
		speed = songData.meta.speed ?? 1.2;
		needVoices = songData.meta.needVoices ?? true;
		stage = songData.meta.stage ?? 'stage';
		countdown = songData.meta.countdown ?? 'default';
		instPrefix = songData.meta.instPrefix ?? '';
		vocPrefix = songData.meta.vocPrefix ?? '';

		vocs = songData.meta.vocs ?? null;

		for (note in songData.notes) {
			noteLane = note.lane ?? 0;
			noteTime = note.time ?? 0;
		}

		RhythmCore.changeBPM(bpmSong);

		chars = songData.gameplay.chars;

		for (i in 0...chars.length) {
			noteSkin = chars[i].strums.noteSkin ?? 'default';
			strumsVisible = chars[i].strums.visible ?? true;
		}
	}

	public static function getSongName(songFolder:String):String {
		var songVariations = [
			songFolder,
			songFolder.toLowerCase(),
			songFolder.toUpperCase(),
			songFolder.substr(0, 1).toUpperCase() + songFolder.substr(1).toLowerCase()
		];

		var foundMeta:Dynamic = null;

		for (name in songVariations) {
			for (lib in ['assets', 'mods']) {
				var candidate = '$lib/songs/$name/charts';
				if (sys.FileSystem.exists(candidate)) {
					var files = sys.FileSystem.readDirectory(candidate);
					for (file in files) {
						if (StringTools.endsWith(file, '.json')) {
							var diffName = file.substr(0, file.length - 5);
							var baseFile = 'songs/$name/charts/$diffName';
							var raw:Dynamic = FormatJson.readJson(Paths.getPath(baseFile, 'json'));
							if (raw != null) {
								foundMeta = raw;
								break;
							}
						}
					}
				}
				if (foundMeta != null)
					break;
			}
			if (foundMeta != null)
				break;
		}

		if (foundMeta == null && modding.vslice.VSlice.isActive())
			foundMeta = modding.vslice.VSliceSongs.chart(songFolder);

		if (foundMeta != null) {
			if (Reflect.hasField(foundMeta, 'meta') && foundMeta.meta != null) {
				var meta = foundMeta.meta;
				if (Reflect.hasField(meta, 'song') && meta.song != null)
					return meta.song;
			}
		}

		return songFolder;
	}

	private function loadSeparateEvents(songFolder:String):Void {
		var path = core.assets.Library.findLib('songs/$songFolder/events.json');
		if (path == null || !sys.FileSystem.exists(path))
			return;

		var raw:Dynamic = FormatJson.readJson(path);
		if (raw == null)
			return;

		var list:Dynamic = Std.isOfType(raw, Array) ? raw : Reflect.field(raw, 'events');
		if (list == null || !Std.isOfType(list, Array))
			return;

		if (songData.gameplay == null)
			songData.gameplay = cast {chars: [], events: []};
		songData.gameplay.events = cast list;
		Console.log('SongData: events loaded from $path');
	}

	private function loadSeparateMeta(raw:Dynamic, songFolder:String):Void {
		var path = core.assets.Library.findLib('songs/$songFolder/meta.json');
		if (path == null || !sys.FileSystem.exists(path))
			return;

		var file:Dynamic = FormatJson.readJson(path);
		if (file == null)
			return;

		var base:Dynamic = raw.meta ?? {};
		for (key in Reflect.fields(file))
			Reflect.setField(base, key, Reflect.field(file, key));
		raw.meta = base;
	}

	private function tryLoadVSliceMeta(songFolder:String):Dynamic {
		var path = core.assets.Library.findLib('songs/$songFolder/$songFolder-metadata.json');
		if (path != null && sys.FileSystem.exists(path)) {
			var meta:Dynamic = FormatJson.readJson(path);
			if (meta != null) {
				Console.log('SongData: V-Slice metadata loaded from $path');
				return meta;
			}
		}
		return null;
	}
}

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

typedef NoteData = {
	var ?char:Null<String>;
	var ?lane:Null<Int>;
	var ?time:Null<Float>;
	var ?type:Null<String>;
	var ?length:Null<Float>;

	// v2
	var ?l:Null<Int>;
	var ?t:Null<Float>;
	var ?d:Null<Int>;
	var ?c:Null<String>;
}

class NoteDataUtil {
	// to v2
	public static function normalize(notes:Array<NoteData>, lbase:Float):Void {
		for (n in notes) {
			if (n.l == null && n.t == null && n.d == null && n.c == null)
				continue;

			if (n.lane == null)
				n.lane = n.l ?? 0;
			if (n.time == null)
				n.time = n.t ?? 0.0;
			if (n.char == null)
				n.char = n.c ?? '';
			if (n.type == null)
				n.type = 'normal';
			if (n.length == null)
				n.length = (n.d != null && lbase > 0) ? n.d * lbase : 0.0;

			Reflect.deleteField(n, 'l');
			Reflect.deleteField(n, 't');
			Reflect.deleteField(n, 'd');
			Reflect.deleteField(n, 'c');
		}
	}

	public static function toV2(notes:Array<NoteData>, lbase:Float):Array<Dynamic> {
		var out:Array<Dynamic> = [];
		for (n in notes) {
			var d:Dynamic = {
				l: n.lane,
				t: n.time,
				c: n.char
			};
			var lenIdx:Int = (lbase > 0) ? Math.round((n.length ?? 0) / lbase) : 0;
			Reflect.setField(d, 'd', lenIdx);
			if (n.type != null && n.type != 'normal')
				Reflect.setField(d, 'type', n.type);
			out.push(d);
		}
		return out;
	}
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

	public var lbase:Float = 0.0;

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

			if (raw.lbase != null) {
				lbase = cast raw.lbase;
				NoteDataUtil.normalize(songData.notes, lbase);
			}

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
		var metaPath = core.assets.Library.findLib('songs/$songFolder/meta.json');
		if (metaPath != null) {
			var file:Dynamic = FormatJson.readJson(metaPath);
			if (file?.song != null)
				return file.song;
		}

		if (modding.vslice.VSlice.isActive()) {
			var meta:Dynamic = modding.vslice.VSliceSongs.metadata(songFolder);
			if (meta?.songName != null)
				return meta.songName;
		}

		var chartsPath = core.assets.Library.findLib('songs/$songFolder/charts');
		if (chartsPath != null) {
			for (file in sys.FileSystem.readDirectory(chartsPath)) {
				if (StringTools.endsWith(file, '.json')) {
					var raw:Dynamic = FormatJson.readJson('$chartsPath/$file');
					if (raw?.meta?.song != null)
						return raw.meta.song;
					break;
				}
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

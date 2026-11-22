package core.json.song;

import core.rhythm.RhythmCore;

class SongConfig {
	public var songData:SongData;

	public var songName:String = 'Fresh';
	public var bpmSong:Float = 120;
	public var speed:Float = 1.2;
	public var needVoices:Bool = true;
	public var stage:String = 'stage';
	public var countdown:String = 'default';

	public var chars:Array<SongData.CharDataJson> = [];

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
		var baseFile = 'game/songs/$songFolder/charts/$diff';
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

			if (meta == null)
				meta = tryLoadVSliceMeta(songFolder, diff);

			var converted = ChartPorter.tryConvert(raw, diff, meta);
			songData = converted ?? cast raw;
			loadSeparateMeta(raw, songFolder);

			if (raw.lbase != null) {
				lbase = cast raw.lbase;
				SongData.NoteDataUtil.normalize(songData.notes, lbase);
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
		var metaPath = core.assets.Library.findLib('game/songs/$songFolder/meta.json');
		if (metaPath != null) {
			var file:Dynamic = FormatJson.readJson(metaPath);
			if (file?.displayName != null)
				return file.displayName;
			if (file?.song != null)
				return file.song;
		}

		if (modding.vslice.VSlice.isActive()) {
			var meta:Dynamic = modding.vslice.VSliceSongs.metadata(songFolder);
			if (meta?.songName != null)
				return meta.songName;
		}

		var chartsPath = core.assets.Library.findLib('game/songs/$songFolder/charts');
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
		var path = core.assets.Library.findLib('game/songs/$songFolder/events.json');
		if (path == null || !sys.FileSystem.exists(path))
			return;

		var raw:Dynamic = FormatJson.readJson(path);
		if (raw == null)
			return;

		var list:Dynamic = null;

		if (Std.isOfType(raw, Array))
			list = raw;
		else if (Reflect.field(raw, 'events') != null)
			list = Reflect.field(raw, 'events');
		else if (Reflect.field(raw, 'song') != null) {
			var songObj:Dynamic = Reflect.field(raw, 'song');
			var psychEvents:Dynamic = Reflect.field(songObj, 'events');
			if (psychEvents != null && Std.isOfType(psychEvents, Array))
				list = core.json.song.ports.NMVPorter.convertPsychEvents(cast psychEvents);
		}

		if (list == null || !Std.isOfType(list, Array))
			return;

		if (songData.gameplay == null)
			songData.gameplay = cast {chars: [], events: []};
		songData.gameplay.events = cast list;
		Console.log('SongData: events loaded from $path');
	}

	private function loadSeparateMeta(raw:Dynamic, songFolder:String):Void {
		var path = core.assets.Library.findLib('game/songs/$songFolder/meta.json');
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

	private function tryLoadVSliceMeta(songFolder:String, diff:String):Dynamic {
		var diffMeta:String = (diff != 'easy' && diff != 'normal' && diff != 'hard') ? '-$diff' : '';
		var path = Paths.getPath('songs/$songFolder/$songFolder-metadata$diffMeta',
			'json') ?? Paths.getPath('game/songs/$songFolder/$songFolder-metadata$diffMeta', 'json');
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

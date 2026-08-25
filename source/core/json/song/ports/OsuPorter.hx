package core.json.song.ports;

import sys.io.File;
import sys.FileSystem;
import core.json.song.SongData;

class OsuPorter implements FormatChartConverter {
	static final PLAYER_CHAR:String = 'bf';
	static final OPPONENT_CHAR:String = 'dad';
	static final DEFAULT_SPEED:Float = 1.6;

	public function new() {}

	public function detect(raw:Dynamic):Bool {
		return false;
	}

	public function convert(raw:Dynamic):SongData {
		return null;
	}

	public static function readOsu(path:String):Null<SongData> {
		if (path == null || !FileSystem.exists(path))
			return null;

		var content:String = File.getContent(path);
		return parseOsu(content);
	}

	public static function parseOsu(content:String):Null<SongData> {
		var lines = content.split('\n');

		var section:String = '';
		var mode:Int = -1;
		var title:String = 'Unknown';
		var bpm:Float = 120.0;
		var numCols:Int = 4;

		var firstBpmMs:Float = -1.0;

		var hitObjects:Array<String> = [];

		for (rawLine in lines) {
			var line = StringTools.trim(rawLine);
			if (line == '' || line.substr(0, 2) == '//')
				continue;

			if (line.charAt(0) == '[' && line.charAt(line.length - 1) == ']') {
				section = line.substr(1, line.length - 2);
				continue;
			}

			switch (section) {
				case 'General':
					var kv = splitKV(line);
					if (kv != null && kv.key == 'Mode')
						mode = Std.parseInt(kv.value);

				case 'Metadata':
					var kv = splitKV(line);
					if (kv != null && kv.key == 'Title')
						title = kv.value;

				case 'Difficulty':
					var kv = splitKV(line);
					if (kv != null && kv.key == 'CircleSize')
						numCols = Std.int(Std.parseFloat(kv.value));

				case 'TimingPoints':
					if (firstBpmMs < 0) {
						var parts = line.split(',');
						if (parts.length >= 2) {
							var beatLen = Std.parseFloat(parts[1]);
							if (beatLen > 0)
								firstBpmMs = beatLen;
						}
					}

				case 'HitObjects':
					hitObjects.push(line);
			}
		}

		if (mode != 3) {
			trace('[OsuPorter] Ignored: Mode $mode is not osu!mania (3).');
			return null;
		}

		// Only 4K (normal) and 8K (split: opponent left / player right) are supported
		if (numCols != 4 && numCols != 8) {
			trace('[OsuPorter] Ignored: $numCols-key maps are not supported.');
			return null;
		}

		if (firstBpmMs > 0)
			bpm = 60000.0 / firstBpmMs;

		var notes:Array<NoteData> = numCols == 8 ? parseHitObjectsSplit(hitObjects) : parseHitObjects(hitObjects);

		notes.sort((a, b) -> a.time < b.time ? -1 : 1);

		var chars:Array<CharDataJson> = numCols == 8 ? [
			{
				id: OPPONENT_CHAR,
				name: OPPONENT_CHAR,
				role: 'opponent',
				strums: {
					position: [50, 0]
				}
			},
			{
				id: PLAYER_CHAR,
				name: PLAYER_CHAR,
				role: 'player',
				strums: {
					position: [720, 0]
				}
			}
		] : [
			{
				id: PLAYER_CHAR,
				name: PLAYER_CHAR,
				role: 'player',
				strums: {
					position: [720, 0]
				}
			}
			];

		return {
			meta: {
				song: title,
				bpm: bpm,
				speed: DEFAULT_SPEED,
				needVoices: true,
				stage: 'stage'
			},
			gameplay: {
				chars: chars,
				events: []
			},
			notes: notes
		};
	}

	// 4K: lanes 0-3, all player
	static function parseHitObjects(lines:Array<String>):Array<NoteData> {
		var notes:Array<NoteData> = [];

		for (line in lines) {
			var parts = line.split(',');
			if (parts.length < 5)
				continue;

			var x = Std.parseFloat(parts[0]);
			var time = Std.parseFloat(parts[2]);
			var type = Std.parseInt(parts[3]);

			var lane:Int = Std.int(Math.floor(x * 4 / 512));
			if (lane < 0)
				lane = 0;
			if (lane > 3)
				lane = 3;

			var length:Float = parseLongNoteLength(parts, type, time);

			notes.push({
				char: PLAYER_CHAR,
				lane: lane,
				time: time,
				type: 'normal',
				length: length
			});
		}

		return notes;
	}

	// 8K: lanes 0-3 → opponent, lanes 4-7 → player (remapped to 0-3)
	static function parseHitObjectsSplit(lines:Array<String>):Array<NoteData> {
		var notes:Array<NoteData> = [];

		for (line in lines) {
			var parts = line.split(',');
			if (parts.length < 5)
				continue;

			var x = Std.parseFloat(parts[0]);
			var time = Std.parseFloat(parts[2]);
			var type = Std.parseInt(parts[3]);

			var rawLane:Int = Std.int(Math.floor(x * 8 / 512));
			if (rawLane < 0)
				rawLane = 0;
			if (rawLane > 7)
				rawLane = 7;

			var charId:String = rawLane < 4 ? OPPONENT_CHAR : PLAYER_CHAR;
			var lane:Int = rawLane < 4 ? rawLane : rawLane - 4;

			var length:Float = parseLongNoteLength(parts, type, time);

			notes.push({
				char: charId,
				lane: lane,
				time: time,
				type: 'normal',
				length: length
			});
		}

		return notes;
	}

	static function parseLongNoteLength(parts:Array<String>, type:Int, time:Float):Float {
		if ((type & 128) != 0 && parts.length >= 6) {
			var endStr = parts[5].split(':')[0];
			var endTime = Std.parseFloat(endStr);
			if (endTime > time)
				return endTime - time;
		}
		return 0.0;
	}

	static function splitKV(line:String):Null<{key:String, value:String}> {
		var idx = line.indexOf(':');
		if (idx < 0)
			return null;
		return {
			key: StringTools.trim(line.substr(0, idx)),
			value: StringTools.trim(line.substr(idx + 1))
		};
	}
}

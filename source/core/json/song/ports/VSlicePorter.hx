package core.json.song.ports;

import core.json.song.SongData.EventsData;
import core.json.song.SongData.NoteData;

class VSlicePorter implements FormatChartConverter {
	public function new() {}

	public function detect(raw:Dynamic):Bool {
		return raw.version != null && raw.notes != null && raw.scrollSpeed != null && !Std.isOfType(raw.notes, Array);
	}

	public function convert(raw:Dynamic):SongData {
		var songName:String = raw._songName ?? 'unknown';
		var bpm:Float = raw._bpm ?? 120.0;
		var stage:String = raw._stage ?? 'stage';
		var player:String = raw._player ?? 'bf';
		var opponent:String = raw._opponent ?? 'dad';
		var girlfriend:String = raw._girlfriend ?? 'gf';

		var diff:Null<String> = raw._diff;
		var notesObj:Dynamic = raw.notes;
		var availDiffs:Array<String> = Reflect.fields(notesObj);

		var resolvedDiff:String;
		if (diff != null && Reflect.hasField(notesObj, diff))
			resolvedDiff = diff;
		else if (availDiffs.length > 0)
			resolvedDiff = availDiffs[0];
		else {
			return makeEmpty(songName, bpm, stage, player, opponent, girlfriend);
		}

		var rawNotes:Array<Dynamic> = cast Reflect.field(notesObj, resolvedDiff);

		var speedObj:Dynamic = raw.scrollSpeed;
		var speed:Float = 1.0;
		if (Reflect.hasField(speedObj, resolvedDiff))
			speed = cast Reflect.field(speedObj, resolvedDiff);
		else {
			var speedFields = Reflect.fields(speedObj);
			if (speedFields.length > 0)
				speed = cast Reflect.field(speedObj, speedFields[0]);
		}

		var notes:Array<NoteData> = [];
		for (n in rawNotes) {
			var t:Float = n.t ?? 0.0;
			var d:Int = n.d ?? 0;
			var l:Float = n.l ?? 0.0;

			var lane:Int = d % 4;
			var isOpponent = d >= 4;

			notes.push({
				char: isOpponent ? opponent : player,
				lane: lane,
				time: t,
				type: 'normal',
				length: l
			});
		}
		notes.sort((a, b) -> a.time < b.time ? -1 : 1);

		var events:Array<EventsData> = [];
		if (raw.events != null) {
			for (ev in (raw.events : Array<Dynamic>)) {
				var evName:String = ev.e ?? 'Unknown';
				var evTime:Float = ev.t ?? 0.0;
				var evVal:Dynamic = ev.v ?? {};

				if (evName == 'FocusCamera') {
					var charIdx:Int = evVal.char ?? 0;
					var focusChar = charIdx == 0 ? player : opponent;
					events.push({
						time: evTime,
						name: 'Camera Follow',
						arguments: {char: focusChar}
					});
				} else {
					events.push({
						time: evTime,
						name: evName,
						arguments: evVal
					});
				}
			}
		}
		events.sort((a, b) -> a.time < b.time ? -1 : 1);

		var instCustom:Null<String> = raw._instCustom;

		var vocs:Null<Array<String>> = raw._vocs;

		return {
			meta: {
				song: songName,
				bpm: bpm,
				speed: speed,
				needVoices: true,
				stage: stage,
				instCustom: instCustom,
				vocs: vocs
			},
			gameplay: {
				chars: [
					{
						id: girlfriend,
						name: girlfriend,
						role: 'gf',
						strums: {
							position: [0, 0],
							visible: false,
							notesVisible: false
						}
					},
					{
						id: player,
						name: player,
						role: 'player',
						strums: {
							position: [720, 0]
						}
					},
					{
						id: opponent,
						name: opponent,
						role: 'opponent',
						strums: {
							position: [50, 0]
						}
					}
				],
				events: events
			},
			notes: notes
		};
	}

	private function makeEmpty(song:String, bpm:Float, stage:String, player:String, opponent:String, girlfriend:String):SongData {
		return {
			meta: {
				song: song,
				bpm: bpm,
				speed: 1.0,
				stage: stage
			},
			gameplay: {
				chars: [
					{
						id: girlfriend,
						name: girlfriend,
						role: 'gf',
						strums: {position: [0, 0], visible: false, notesVisible: false}
					},
					{
						id: player,
						name: player,
						role: 'player',
						strums: {position: [720, 0]}
					},
					{
						id: opponent,
						name: opponent,
						role: 'opponent',
						strums: {position: [50, 0]}
					}
				],
				events: []
			},
			notes: []
		};
	}
}

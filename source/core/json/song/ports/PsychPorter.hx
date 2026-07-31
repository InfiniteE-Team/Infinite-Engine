package core.json.song.ports;

import core.json.song.SongData.EventsData;
import core.json.song.SongData.NoteData;

class PsychPorter implements FormatChartConverter {
	public function new() {}

	public function detect(raw:Dynamic):Bool {
		var song = raw.song;
		return song != null && song.notes != null && (song.events != null || song.player3 != null || song.gfVersion != null);
	}

	public function convert(raw:Dynamic):SongData {
		var song = raw.song;
		var p1:String = song.player1 ?? 'bf';
		var p2:String = song.player2 ?? 'dad';
		var p3:String = song.player3 ?? song.gfVersion ?? 'gf';

		var events:Array<EventsData> = [];

		var notes:Array<NoteData> = [];
		for (section in (song.notes : Array<Dynamic>)) {
			var mustHit:Bool = section.mustHitSection ?? true;
			var sectionNotes:Array<Array<Float>> = section.sectionNotes;
			var sectionStart:Null<Float> = null;

			for (note in sectionNotes) {
				var lane = Std.int(note[1]);
				var over = lane > 3;
				notes.push({
					char: over ? p2 : p1,
					lane: over ? lane - 4 : lane,
					time: note[0],
					type: 'normal',
					length: note[2]
				});

				if (sectionStart == null || note[0] < sectionStart)
					sectionStart = note[0];
			}

			if (sectionStart != null) {
				events.push({
					time: sectionStart,
					name: 'Camera Follow',
					arguments: {char: mustHit ? p1 : p2}
				});
			}
		}
		notes.sort((a, b) -> a.time < b.time ? -1 : 1);

		if (song.events != null) {
			for (event in (song.events : Array<Dynamic>)) {
				var time:Float = event[0];
				for (action in (event[1] : Array<Dynamic>)) {
					events.push({
						time: time,
						name: Std.string(action[0]),
						arguments: {value1: action[1], value2: action[2]}
					});
				}
			}
		}

		return {
			meta: {
				song: song.song ?? 'Unknown',
				bpm: song.bpm ?? 120,
				speed: song.speed ?? 1.0,
				needVoices: song.needsVoices ?? true,
				stage: song.stage ?? 'stage'
			},
			gameplay: {
				chars: [
					{
						id: p3,
						name: p3,
						role: 'gf',
						strums: {
							position: [0, 0],
							visible: false
						}
					},
					{
						id: p1,
						name: p1,
						role: 'player',
						strums: {
							position: [720, 0]
						}
					},
					{
						id: p2,
						name: p2,
						role: 'opponent',
						strums: {
							position: [50, 0]
						}
					},
				],
				events: events
			},
			notes: notes
		};
	}
}

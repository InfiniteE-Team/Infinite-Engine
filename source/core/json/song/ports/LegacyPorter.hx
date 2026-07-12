package core.json.song.ports;
import core.json.song.SongData.EventsData;
import core.json.song.SongData.NoteData;

class LegacyPorter implements FormatChartConverter {
	public function new () {}
	public function detect(raw:Dynamic):Bool {
		var song = raw.song;
		return song != null && song.notes != null && song.events == null && song.player3 == null && song.gfVersion == null;
	}

	public function convert(raw:Dynamic):SongData {
		var legacy = raw.song;
		var p1:String = legacy.player1 ?? 'bf';
		var p2:String = legacy.player2 ?? 'dad';
		var notes:Array<NoteData> = [];
		var events:Array<EventsData> = [];

		for (section in (legacy.notes : Array<Dynamic>)) {
			var mustHit:Bool = section.mustHitSection ?? true;
			var sectionNotes:Array<Array<Float>> = section.sectionNotes;
			var sectionStart:Null<Float> = null;

			for (note in sectionNotes) {
				var lane = Std.int(note[1]);
				var isP2 = lane > 3;
				notes.push({
					char: (isP2 ? !mustHit : mustHit) ? p1 : p2,
					lane: isP2 ? lane - 4 : lane,
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

		return {
			meta: {song: legacy.song, bpm: legacy.bpm, speed: legacy.speed},
			gameplay: {
				chars: [
					{
						id: p1,
						name: p1,
						role: 'player',
						strumPos: [720, 0]
					},
					{
						id: p2,
						name: p2,
						role: 'opponent',
						strumPos: [50, 0]
					}
				],
				events: events
			},
			notes: notes
		};
	}
}

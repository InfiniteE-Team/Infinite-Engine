package core.json.song.ports;
import core.json.song.SongData.NoteData;

class LegacyPorter implements FormatChartConverter {
	public function new () {}
	public function detect(raw:Dynamic):Bool {
		var s = raw.song;
		return s != null && s.notes != null && s.events == null && s.player3 == null && s.gfVersion == null;
	}

	public function convert(raw:Dynamic):SongData {
		var legacy = raw.song;
		var p1:String = legacy.player1 ?? 'bf';
		var p2:String = legacy.player2 ?? 'dad';
		var notes:Array<NoteData> = [];

		for (section in (legacy.notes : Array<Dynamic>)) {
			var mustHit:Bool = section.mustHitSection ?? true;
			for (n in (section.sectionNotes : Array<Array<Float>>)) {
				var lane = Std.int(n[1]);
				var isP2 = lane > 3;
				notes.push({
					char: (isP2 ? !mustHit : mustHit) ? p1 : p2,
					lane: isP2 ? lane - 4 : lane,
					time: n[0],
					type: 'normal',
					length: n[2]
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
						strumPos: [650, 0]
					},
					{
						id: p2,
						name: p2,
						role: 'opponent',
						strumPos: [50, 0]
					}
				],
				events: []
			},
			notes: notes
		};
	}
}

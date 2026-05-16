package core.json.song.ports;
import core.json.song.SongData.EventsData;
import core.json.song.SongData.NoteData;

class PsychPorter implements FormatChartConverter {
    public function new () {}
	public function detect(raw:Dynamic):Bool {
		var s = raw.song;
		return s != null && s.notes != null && (s.events != null || s.player3 != null || s.gfVersion != null);
	}

	public function convert(raw:Dynamic):SongData {
		var s = raw.song;
		var p1:String = s.player1 ?? 'bf';
		var p2:String = s.player2 ?? 'dad';
		var p3:String = s.player3 ?? s.gfVersion ?? 'gf';

		var notes:Array<NoteData> = [];
		for (section in (s.notes : Array<Dynamic>)) {
			var mustHit:Bool = section.mustHitSection ?? true;
			for (n in (section.sectionNotes : Array<Array<Float>>)) {
				var lane = Std.int(n[1]);
				var over = lane > 3;
				notes.push({
					char: (!over ? mustHit : !mustHit) ? p1 : p2,
					lane: over ? lane - 4 : lane,
					time: n[0],
					type: 'normal',
					length: n[2]
				});
			}
		}
		notes.sort((a, b) -> a.time < b.time ? -1 : 1);

		var events:Array<EventsData> = [];
		if (s.events != null) {
			for (ev in (s.events : Array<Dynamic>)) {
				var time:Float = ev[0];
				for (action in (ev[1] : Array<Dynamic>)) {
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
				song: s.song ?? 'Unknown',
				bpm: s.bpm ?? 120,
				speed: s.speed ?? 1.0,
				needVoices: s.needsVoices ?? true,
				stage: s.stage ?? 'stage'
			},
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
					},
					{
						id: p3,
						name: p3,
						role: 'gf',
						strumPos: [0, 0]
					}
				],
				events: events
			},
			notes: notes
		};
	}
}

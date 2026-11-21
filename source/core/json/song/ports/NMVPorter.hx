package core.json.song.ports;

class NMVPorter implements FormatChartConverter {
	public function new() {}

	public function detect(raw:Dynamic):Bool {
		if (raw.song == null)
			return false;
		var s:Dynamic = raw.song;
		return s.bpm != null && s.notes != null && raw.meta == null;
	}

	public function convert(raw:Dynamic):SongData {
		var s:Dynamic = raw.song;

		var meta:SongData.MetaData = {
			song: s.song ?? 'Unknown',
			bpm: s.bpm ?? 100.0,
			speed: s.speed ?? 1.0,
			stage: s.stage,
			needVoices: s.needsVoices ?? true
		};

		var p1Id:String = s.player1 ?? 'bf';
		var p2Id:String = s.player2 ?? 'dad';
		var gfId:String = s.gfVersion ?? s.player3 ?? 'gf';

		var skins:Array<Dynamic> = cast s.arrowSkins ?? [];

		var chars:Array<SongData.CharDataJson> = [
			{
				id: p2Id,
				role: 'dad',
				strums: {
					noteSkin: skins.length >= 1 ? cast skins[0] : 'default',
					visible: true
				}
			},
			{
				id: p1Id,
				role: 'boyfriend',
				strums: {
					noteSkin: skins.length >= 2 ? cast skins[1] : 'default',
					visible: true
				}
			},
			{
				id: gfId,
				role: 'girlfriend',
				strums: {
					noteSkin: 'default',
					visible: false,
					notesVisible: false
				}
			}
		];

		// Format: [time, lane, length, type:String, ?altAnim:Bool]
		var notes:Array<SongData.NoteData> = [];
		var sections:Array<Dynamic> = cast s.notes ?? [];
		var keyCount:Int = s.keys ?? 4;

		for (section in sections) {
			var mustHit:Bool = section.mustHitSection ?? false;
			var sNotes:Array<Dynamic> = cast section.sectionNotes ?? [];

			for (n in sNotes) {
				var time:Float = cast n[0];
				var rawLane:Int = Std.int(cast n[1]);
				var length:Float = n[2] != null ? cast n[2] : 0.0;

				var noteType:String = (n[3] != null && Std.string(n[3]) != '') ? Std.string(n[3]) : 'normal';

				var isAlt:Bool = n[4] != null && n[4] == true;

				var isPlayerSide:Bool = rawLane >= keyCount;
				var lane:Int = rawLane % keyCount;
				var charId:String;

				if (isPlayerSide) {
					charId = mustHit ? p2Id : p1Id;
				} else {
					charId = mustHit ? p1Id : p2Id;
				}

				notes.push({
					char: charId,
					lane: lane,
					time: time,
					length: length,
					type: noteType
				});
			}
		}

		var events:Array<SongData.EventsData> = convertPsychEvents(cast s.events ?? []);

		return {
			meta: meta,
			gameplay: {chars: chars, events: events},
			notes: notes
		};
	}

	public static function convertPsychEvents(raw:Array<Dynamic>):Array<SongData.EventsData> {
		var out:Array<SongData.EventsData> = [];
		for (e in raw) {
			if (e == null)
				continue;
			var time:Float = cast e[0];

			if (Std.isOfType(e[1], Array)) {
				var tuples:Array<Dynamic> = cast e[1];
				for (t in tuples) {
					if (t == null)
						continue;
					out.push({
						name: Std.string(t[0] ?? ''),
						time: time,
						arguments: [Std.string(t[1] ?? ''), Std.string(t[2] ?? '')]
					});
				}
			} else {
				out.push({
					name: Std.string(e[1] ?? ''),
					time: time,
					arguments: [Std.string(e[2] ?? ''), Std.string(e[3] ?? '')]
				});
			}
		}
		return out;
	}
}

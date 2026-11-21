package core.json.song.ports;

class CNEPorter implements FormatChartConverter {
	public function new() {}

	public function detect(raw:Dynamic):Bool {
		return raw.codenameChart == true || raw.chartVersion != null;
	}

	public function convert(raw:Dynamic):SongData {
		var strumLines:Array<Dynamic> = cast raw.strumLines ?? [];
		var events:Array<Dynamic> = cast raw.events ?? [];

		var meta:SongData.MetaData = {
			song: raw._songName ?? 'Unknown',
			bpm: raw._bpm ?? 160.0,
			speed: raw.scrollSpeed ?? 1.0,
			stage: raw.stage,
			needVoices: true
		};

		var chars:Array<SongData.CharDataJson> = [];
		for (sl in strumLines) {
			var charList:Array<Dynamic> = cast sl.characters ?? [];
			var id:String = charList.length > 0 ? cast charList[0] : 'bf';

			var role:String = switch (Std.string(sl.position)) {
				case 'dad' | 'opponent': 'dad';
				case 'girlfriend' | 'gf': 'girlfriend';
				default: 'boyfriend';
			};

			var strum:SongData.StrumsData = {
				visible: sl.visible ?? true,
				noteSkin: 'default',
				position: sl.strumPos,
				scale: sl.strumScale != null ? [sl.strumScale, sl.strumScale] : null,
				notesVisible: sl.type != 2
			};

			chars.push({
				id: id,
				role: role,
				strums: strum
			});
		}

		var notes:Array<SongData.NoteData> = [];
		for (sl in strumLines) {
			if (sl.type == 2)
				continue;
			var charList:Array<Dynamic> = cast sl.characters ?? [];
			var charId:String = charList.length > 0 ? cast charList[0] : 'bf';

			var slNotes:Array<Dynamic> = cast sl.notes ?? [];
			for (n in slNotes) {
				notes.push({
					char: charId,
					lane: cast n.id,
					time: cast n.time,
					length: n.sLen != null ? cast n.sLen : 0.0,
					type: n.type != null && n.type != 0 ? Std.string(n.type) : 'normal'});
			}
		}

		var convertedEvents:Array<SongData.EventsData> = [];
		for (e in events) {
			var params:Dynamic = e.params ?? [];
			convertedEvents.push({
				name: cast e.name,
				time: cast e.time,
				arguments: params
			});
		}

		return {
			meta: meta,
			gameplay: {chars: chars, events: convertedEvents},
			notes: notes
		};
	}
}

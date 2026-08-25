package core.json.song.ports;

import core.json.song.SongData.EventsData;
import core.json.song.SongData.NoteData;

class AndromedaPorter implements FormatChartConverter {
	public function new() {}

	public function detect(raw:Dynamic):Bool {
		var song = raw.song;
		return song != null
			&& song.notes != null
			&& (song.notes.events != null || song.events != null || song.player3 != null || song.gfVersion != null);
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

			if (section.events != null) {
				for (secEventGroup in (section.events : Array<Dynamic>)) {
					var eventTime:Float = secEventGroup.time;
					if (secEventGroup.events != null) {
						for (eventData in (secEventGroup.events : Array<Dynamic>)) {
							var args:Array<Dynamic> = eventData.args ?? [];
							events.push({
								time: eventTime,
								name: Std.string(eventData.name),
								arguments: {
									value1: args[0],
									value2: args[1],
									value3: args[2]
								}
							});
						}
					}
				}
			}

			for (note in sectionNotes) {
				var rawLane:Int = Std.int(note[1]);
				var noteTime:Float = note[0];

				var char:String = p1;
				var lane:Int = rawLane;

				if (rawLane > 3) {
					lane = rawLane - 4;
					char = mustHit ? p1 : p2;
				} else {
					char = mustHit ? p2 : p1;
				}

				notes.push({
					char: char,
					lane: lane,
					time: noteTime,
					type: 'normal',
					length: note[2]
				});

				if (sectionStart == null || noteTime < sectionStart)
					sectionStart = noteTime;
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
						arguments: {
							value1: action[1],
							value2: action[2],
							value3: action[3]
						}
					});
				}
			}
		}

		return {
			meta: {
				song: song.song ?? 'Unknown',
				bpm: song.bpm ?? 120,
				speed: song.speed ?? song.initialSpeed ?? 1.0,
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
							visible: false,
							notesVisible: false
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

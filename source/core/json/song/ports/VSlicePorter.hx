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
		var noteSkin:Null<String> = modding.vslice.VSliceNoteStyles.skinFor(raw._noteStyle);

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
				char: isOpponent ? 'dad' : 'bf',
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

				var mapped = mapEvent(evName, evVal, speed);
				if (mapped != null) {
					mapped.args.vsKind = evName;
					mapped.args.vsValue = evVal;
				}
				events.push({
					time: evTime,
					name: mapped?.name ?? evName,
					arguments: mapped?.args ?? evVal
				});
			}
		}
		events.sort((a, b) -> a.time < b.time ? -1 : 1);

		var instPrefix:Null<String> = raw._instPrefix;

		var vocPrefix:Null<String> = raw._vocPrefix;

		var vocs:Null<Array<String>> = raw._vocs;

		return {
			meta: {
				song: songName,
				bpm: bpm,
				speed: speed,
				needVoices: true,
				stage: stage,
				instPrefix: instPrefix,
				vocPrefix: vocPrefix,
				vocs: vocs
			},
			gameplay: {
				chars: [
					{
						id: 'gf',
						name: girlfriend,
						role: 'gf',
						strums: {
							position: [0, 0],
							visible: false,
							notesVisible: false
						}
					},
					{
						id: 'bf',
						name: player,
						role: 'player',
						strums: {
							position: [720, 0],
							noteSkin: noteSkin
						}
					},
					{
						id: 'dad',
						name: opponent,
						role: 'opponent',
						strums: {
							position: [50, 0],
							noteSkin: noteSkin
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
						id: 'gf',
						name: girlfriend,
						role: 'gf',
						strums: {position: [0, 0], visible: false, notesVisible: false}
					},
					{
						id: 'bf',
						name: player,
						role: 'player',
						strums: {position: [720, 0]}
					},
					{
						id: 'dad',
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

	static function mapEvent(name:String, v:Dynamic, songSpeed:Float):Null<{name:String, args:Dynamic}> {
		switch (name) {
			case 'FocusCamera':
				var charIdx:Int = v.char ?? 0;
				return {name: 'Camera Follow', args: {
					char: charIdx < 0 ? '' : (charIdx == 0 ? 'bf' : (charIdx == 2 ? 'gf' : 'dad')),
					x: v.x ?? 0.0,
					y: v.y ?? 0.0,
					duration: v.duration ?? 4.0,
					ease: easeName(v.ease ?? 'CLASSIC', v.easeDir)
				}};
			case 'ZoomCamera':
				return {name: 'Zoom Camera', args: {
					zoom: v.zoom ?? 1.0,
					duration: v.duration ?? 4.0,
					ease: easeName(v.ease, v.easeDir),
					mode: v.mode ?? 'direct'
				}};
			case 'SetCameraBop':
				return {name: 'Camera Bop', args: {rate: v.rate ?? 4, intensity: v.intensity ?? 1.0}};
			case 'PlayAnimation':
				var target:String = Std.string(v.target ?? 'bf');
				var char = switch (target) {
					case 'boyfriend' | 'bf' | 'player': 'bf';
					case 'girlfriend' | 'gf': 'gf';
					case 'dad' | 'opponent': 'dad';
					default: target;
				};
				return {name: 'Play Special Anim', args: {char: char, anim: v.anim}};
			case 'ScrollSpeed':
				var scroll:Float = v.scroll ?? 1.0;
				return {name: 'Change Scroll Speed', args: {
					speed: v.absolute == true ? scroll : scroll * songSpeed,
					duration: v.duration ?? 4.0,
					ease: easeName(v.ease ?? 'linear', v.easeDir)
				}};
			default:
				return null;
		}
	}

	static function easeName(ease:String, dir:String):String {
		if (ease == null)
			return 'linear';
		if (ease == 'INSTANT' || ease == 'CLASSIC' || ease == 'linear' || dir == null || dir == '')
			return ease;
		return ease + dir;
	}
}

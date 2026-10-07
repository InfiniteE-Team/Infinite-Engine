package modding.editors.gameplay;

import core.json.song.SongData;
import core.assets.Library;
import modding.mods.ModsRegistry;
import sys.FileSystem;

class ChartDefaults {
	public static final FALLBACK_STAGE:String = 'stage';
	public static final FALLBACK_CHAR:String = 'bf';

	public static final DEFAULT_BPM:Float = 120;
	public static final DEFAULT_SPEED:Float = 1.3;

	public static function defaultChars():Array<CharDataJson> {
		return [
			{
				id: 'gf',
				name: 'gf',
				role: 'gf',
				strums: {position: [50, 0], visible: false, notesVisible: false}
			},
			{
				id: 'bf',
				name: 'bf',
				role: 'player',
				strums: {position: [720, 0]}
			},
			{
				id: 'dad',
				name: 'dad',
				role: 'opponent',
				strums: {position: [50, 0]}
			}
		];
	}

	public static function blankChart(song:String, bpm:Float = 120, stage:String = 'stage'):SongData {
		return {
			meta: {
				song: song,
				bpm: bpm > 0 ? bpm : DEFAULT_BPM,
				speed: DEFAULT_SPEED,
				stage: stage,
				needVoices: false
			},
			gameplay: {
				chars: defaultChars(),
				events: []
			},
			notes: []
		};
	}

	public static function repair(data:SongData, songFolder:String):Array<String> {
		var fixes:Array<String> = [];

		if (data.meta == null) {
			data.meta = {song: songFolder, bpm: DEFAULT_BPM, speed: DEFAULT_SPEED};
			fixes.push('The chart had no meta: using BPM $DEFAULT_BPM.');
		}
		if (Reflect.field(data.meta, 'song') == null)
			data.meta.song = songFolder;
		if (Reflect.field(data.meta, 'bpm') == null || data.meta.bpm <= 0) {
			data.meta.bpm = DEFAULT_BPM;
			fixes.push('The chart had no valid BPM: using $DEFAULT_BPM.');
		}
		if (Reflect.field(data.meta, 'speed') == null || data.meta.speed <= 0)
			data.meta.speed = DEFAULT_SPEED;

		if (data.gameplay == null) {
			data.gameplay = {chars: [], events: []};
		}
		if (data.gameplay.events == null)
			data.gameplay.events = [];
		if (data.notes == null)
			data.notes = [];

		var chars:Array<CharDataJson> = [];
		var seen:Map<String, Bool> = new Map();
		for (c in (data.gameplay.chars ?? [])) {
			if (c == null || c.id == null || c.id == '') {
				fixes.push('A character without an id was ignored.');
				continue;
			}
			if (seen.exists(c.id)) {
				fixes.push('Character "${c.id}" appears twice: the second one was ignored.');
				continue;
			}
			seen.set(c.id, true);

			if (c.strums == null)
				c.strums = {};
			if (c.name == null)
				c.name = c.id;
			if (c.role == null)
				c.role = guessRole(c.id, chars.length);

			chars.push(c);
		}

		if (chars.length == 0) {
			chars = defaultChars();
			fixes.push('No characters in the chart: added gf, bf and dad. Press Tab to change them.');
		}
		data.gameplay.chars = chars;

		var notes:Array<NoteData> = [];
		var orphans:Int = 0;
		for (n in data.notes) {
			if (n == null || Reflect.field(n, 'time') == null) {
				fixes.push('A note without a time was removed.');
				continue;
			}
			var time:Float = Std.parseFloat(Std.string(Reflect.field(n, 'time')));
			if (Math.isNaN(time) || time < 0 || !Math.isFinite(time)) {
				fixes.push('A note with an invalid time was removed.');
				continue;
			}
			if (Reflect.field(n, 'lane') == null)
				Reflect.setField(n, 'lane', 0);
			var lane:Float = Std.parseFloat(Std.string(Reflect.field(n, 'lane')));
			if (Math.isNaN(lane) || lane < 0 || lane > 63) {
				fixes.push('A note with an invalid lane was removed.');
				continue;
			}
			if (Reflect.field(n, 'length') == null)
				Reflect.setField(n, 'length', 0);
			var len:Float = Std.parseFloat(Std.string(Reflect.field(n, 'length')));
			if (Math.isNaN(len) || len < 0)
				Reflect.setField(n, 'length', 0);
			if (Reflect.field(n, 'type') == null)
				Reflect.setField(n, 'type', 'normal');
			if (n.char == null || !seen.exists(n.char))
				orphans++;
			notes.push(n);
		}
		data.notes = notes;

		if (orphans > 0)
			fixes.push('$orphans notes belong to a character that is not in the chart. They are hidden in the editor but kept.');

		var stage:String = data.meta.stage ?? FALLBACK_STAGE;
		if (!Paths.exists('data/stages/$stage.json'))
			fixes.push('Stage "$stage" not found: the preview uses "$FALLBACK_STAGE". Press Tab to pick another one.');

		for (c in chars) {
			if (!Paths.exists('data/characters/${c.name}.json'))
				fixes.push('Character "${c.name}" not found: the preview shows "$FALLBACK_CHAR" instead. Press Tab to pick another one.');
		}

		return fixes;
	}

	static function guessRole(id:String, index:Int):String {
		if (game.controllers.CharacterController.namesPlayer.contains(id)
			|| game.controllers.CharacterController.namesOpponent.contains(id)
			|| game.controllers.CharacterController.namesGf.contains(id))
			return id;
		return index == 0 ? 'opponent' : (index == 1 ? 'player' : 'gf');
	}

	public static function listNames(kind:String):Array<String> {
		var folders:Array<String> = ['${Library.baseFolder}/data/$kind'];
		if (ModsRegistry.onMod && ModsRegistry.currentMod != null && ModsRegistry.currentMod != '')
			folders.push('${Library.modsFolder}/${ModsRegistry.currentMod}/data/$kind');

		var names:Array<String> = [];
		for (folder in folders) {
			if (!FileSystem.exists(folder) || !FileSystem.isDirectory(folder))
				continue;
			for (file in FileSystem.readDirectory(folder)) {
				if (!StringTools.endsWith(file, '.json'))
					continue;
				var name = file.substr(0, file.length - 5);
				if (!names.contains(name))
					names.push(name);
			}
		}

		names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return names;
	}

	public static function newChartPath(songFolder:String, diff:String):String {
		var root:String = Library.baseFolder;
		if (ModsRegistry.onMod && ModsRegistry.currentMod != null && ModsRegistry.currentMod != '')
			root = '${Library.modsFolder}/${ModsRegistry.currentMod}';
		return '$root/songs/$songFolder/charts/$diff.json';
	}

	public static function makeDirs(path:String):Void {
		if (path == '' || FileSystem.exists(path))
			return;
		var parent = haxe.io.Path.directory(path);
		if (parent != path)
			makeDirs(parent);
		FileSystem.createDirectory(path);
	}
}
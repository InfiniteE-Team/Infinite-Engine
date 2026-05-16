package game.controllers;

import core.json.objects.NoteSkinData;
import game.objects.sprites.notes.Note;
import game.objects.sprites.notes.StrumNote;
import flixel.group.FlxGroup.FlxTypedGroup;
import utils.UtilsData;
import game.PlayStateConfig;
// song
import core.json.song.SongData.SongConfig;
import core.json.engine.GlobalData.GlobalConfig;
import Lambda;

class NoteController {
	public var isMiss:Bool = false;

	public var length:Float = 0;
	public var direction:Float = 0;

	public var noteSkinData:NoteSkinData;
	public var noteSkin:String = 'default';

	public var noteType:String = 'normal';

	public var strums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var sustains:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();

	public var unspawnNotes:Array<Note> = [];

	public var charStrumOffsets:Map<String, Int> = new Map();

	var daSong:SongConfig = new SongConfig();
	var globalData:GlobalConfig;

	var keys:Int = 4;
	var spacing:Float = 0;

	var input:InputController = new InputController();

	public var scrollSpeed:Float = 1.0;

	// configs
	public var isDownscroll:Bool = false;

	public function new(daSong:SongConfig, isDownscroll:Bool, isGhostTapping:Bool) {
		this.daSong = daSong;
		this.isDownscroll = isDownscroll;
		input.isGhostTapping = isGhostTapping;
		loadJson();
		for (i in 0...daSong.chars.length) {
			charStrumOffsets.set(daSong.chars[i].id, strums.length);

			var strumPos = daSong.chars[i].strumPos;
			loadGenerateStrums(strumPos != null ? strumPos[0] : 0, strumPos != null ? strumPos[1] : 0);
		}
		trace("Created Strums");
	}

	public function loadJson() {
		globalData = Main.globalData;
		if (daSong != null && daSong.noteSkin != null)
			noteSkin = daSong.noteSkin;
		else if (globalData != null)
			noteSkin = globalData.noteSkin;

		// strumnotes
		var noteDataPath:String = 'noteskins/$noteSkin/strumnotes';
		noteSkinData = UtilsData.readJson(Paths.getPath('data/$noteDataPath', "json"));

		keys = noteSkinData.keys ?? 4;
		spacing = noteSkinData.spacing ?? 0;
		scrollSpeed = daSong.speed ?? 1.2;

		// splashes

		// hold splashes

		trace("Note Skin JSON loaded");
	}

	public function loadGenerateStrums(x:Float, y:Float) {
		for (i in 0...keys) {
			var strum = new StrumNote(x + i * (112 + spacing), PlayStateConfig.strumLineY + y, noteSkinData.props, noteSkin);
			strum.ID = i;
			strum.strumLoad(x + i * (112 + spacing), PlayStateConfig.strumLineY + y, noteSkinData.props);
			strum.playAnim('static');
			if (!daSong.strumsVisible)
				strum.visible = false;
			strums.add(strum);
		}
	}

	public function update(songTime:Float) {
		updateNotes(songTime);
	}

	public function updateNotes(songTime:Float) {
		while (unspawnNotes.length > 0) {
			var note = unspawnNotes[0];

			if (isDownscroll && note.y > FlxG.height + 200) {
				unspawnNotes.shift();
				note.destroy();
				continue;
			}

			if (note.strumTime - songTime < 2000) {
				if (note.isSustain)
					sustains.add(note);
				else
					notes.add(note);
				unspawnNotes.shift();
			} else
				break;
		}

		var toDestroy:Array<Note> = [];

		for (note in notes.members) {
			if (note == null)
				continue;
			note.x = note.strum.x;
			if (isDownscroll)
				note.y = note.strum.y - ((note.strumTime - songTime) * scrollSpeed);
			else
				note.y = note.strum.y + ((note.strumTime - songTime) * scrollSpeed);

			if (note.isSustain)
				note.scale.y = (note.length * scrollSpeed) / note.frameHeight;

			if (note.isSustain && note.strumTime + note.length < songTime)
				toDestroy.push(note);
			else if (note.y < -200 && !isDownscroll)
				toDestroy.push(note);
			else if (note.y > FlxG.height + 200 && isDownscroll)
				toDestroy.push(note);
		}

		for (note in toDestroy)
			destroyNotes(note);
	}

	public function destroyNotes(note:Note) {
		if (note.isSustain)
			sustains.remove(note, true);
		else
			notes.remove(note, true);
		note.destroy();
	}

	public function getHittableNote(charId:String, dir:Int, mustPress:Bool = true):Note {
		var offset = charStrumOffsets.get(charId);
		if (offset == null)
			return null;

		for (note in notes.members) {
			if (note == null || !note.alive || note.mustPress != mustPress)
				continue;
			if (note.direction != offset + dir)
				continue;

			var isHittable = mustPress ? (note.canBeHit && !note.wasGoodHit) : note.wasGoodHit;
			if (isHittable)
				return note;
		}
		return null;
	}

	// Creation or Generation for Notes
	public function generateNotes(songTime:Float, daSong:SongConfig) {
		for (data in daSong.songData.notes) {
			// char info
			var charData = Lambda.find(daSong.chars, c -> c.id == data.char);
			if (charData == null)
				continue;

			// offsets for strums or notes for strums group
			var offset = charStrumOffsets.get(charData.id);
			if (offset == null)
				continue;

			// global Lane for strums groups
			var globalLane = offset + data.lane;
			var strum = strums.members[globalLane];
			if (strum == null)
				continue;

			// param for Note positions in strum groups
			var note = new Note(data.time, keys, strum.x, 0, false, noteSkinData.props, noteSkin, data.lane);
			note.ID = globalLane;
			note.direction = globalLane;
			note.strumTime = data.time;
			note.mustPress = CharacterController.namesPlayer.contains(Reflect.field(charData, 'role'));
			if (!daSong.strumsVisible)
				note.visible = false;

			note.strum = strum;

			note.noteType = data.type;

			if (data.length > 0) {
				var sustain = new Note(data.time, keys, strum.x, 0, data.length > 0, noteSkinData.props, noteSkin, data.lane);
				sustain.ID = globalLane;
				sustain.direction = globalLane;
				sustain.strumTime = data.time;
				sustain.mustPress = CharacterController.namesPlayer.contains(Reflect.field(charData, 'role'));
				if (!daSong.strumsVisible)
					sustain.visible = false;

				sustain.strum = strum;

				sustain.noteType = data.type;
				sustain.length = data.length;
				sustain.isSustain = true;
				unspawnNotes.push(sustain);
			}
			unspawnNotes.push(note);
		}

		unspawnNotes.sort(sortNotes);
	}

	public function destroy():Void {
		strums.destroy();
		notes.destroy();
		sustains.destroy();

		strums = null;
		notes = null;
		sustains = null;
	}

	public function getCharStrums(charId:String):Array<StrumNote> {
		if (!charStrumOffsets.exists(charId))
			return [];

		var offset:Int = charStrumOffsets.get(charId);
		var keys:Int = noteSkinData.keys ?? 4;
		var result:Array<StrumNote> = [];

		for (i in 0...keys) {
			var s = strums.members[offset + i];
			if (s != null)
				result.push(s);
		}
		return result;
	}

	function sortNotes(a:Note, b:Note):Int {
		return Std.int(a.strumTime - b.strumTime);
	}
}

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

	public var scrollSpeed:Float = 1.0;

	// configs
	public var isDownscroll:Bool = false;

	public function new(daSong:SongConfig, isDownscroll:Bool) {
		this.daSong = daSong;
		this.isDownscroll = isDownscroll;
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

		var noteDataPath:String = 'noteskins/$noteSkin/skin';
		noteSkinData = UtilsData.readJson(Paths.getPath('data/$noteDataPath', "json"));

		keys = noteSkinData.keys ?? 4;
		spacing = noteSkinData.spacing ?? 0;
		scrollSpeed = daSong.speed ?? 1.2;

		trace("Note Skin JSON loaded");
	}

	public function loadGenerateStrums(x:Float, y:Float) {
		for (i in 0...keys) {
			var strum = new StrumNote(x + i * (202 + spacing), PlayStateConfig.strumLineY + y, noteSkinData.props, noteSkin);
			strum.ID = i;
			strum.playAnim('static');
			strums.add(strum);
		}
	}

	public function update(songTime:Float) {
		updateNotes(songTime);
	}

	public function updateNotes(songTime:Float) {
		while (unspawnNotes.length > 0) {
			var note = unspawnNotes[0];
			if (note.y > FlxG.height + 200) {
				note.kill();
				continue;
			}

			if (note.strumTime - songTime < 2000) {
				notes.add(note);
				unspawnNotes.shift();
			} else
				break;
		}

		for (note in notes.members) {
			if (note == null)
				continue;

			note.x = note.strum.x;

			note.y = note.strum.y - ((note.strumTime - songTime) * scrollSpeed);
		}
	}

	public function getHittableNote(charId:String, dir:Int):Note {
		var offset = charStrumOffsets.get(charId);
		if (offset == null)
			return null;

		var good:Note = null;
		for (note in notes.members) {
			if (note == null || !note.alive || !note.mustPress)
				continue;
			if (note.direction == offset + dir && note.canBeHit && !note.wasGoodHit) {
				if (good == null || note.strumTime < good.strumTime)
					good = note;
			}
		}
		return good;
	}

	public function generateNotes(songTime:Float, daSong:SongConfig) {
		for (data in daSong.songData.notes) {
			var charData = daSong.chars[data.char];
        	if (charData == null) continue;

			// offsets for strums or notes for strums group
			var offset = charStrumOffsets.get(charData.id);
        	if (offset == null) continue;

			// global Lane for strums groups
        	var globalLane = offset + data.lane;
        	var strum = strums.members[globalLane];
        	if (strum == null) continue;

			// param for Note positions in strum groups
			var strum = strums.members[data.lane];
			var note = new Note(data.time, keys, strum.x, 0, data.length > 0, noteSkinData.props, noteSkin, data.lane);
			note.ID = globalLane;
			note.strumTime = data.time;

			note.strum = strum;

			note.noteType = data.type;

			if (data.length > 0)
				note.isSustain = true;

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

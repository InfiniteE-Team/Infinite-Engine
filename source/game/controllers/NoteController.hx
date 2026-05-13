package game.controllers;

import core.json.objects.NoteSkinData;
import game.objects.sprites.notes.Note;
import game.objects.sprites.notes.StrumNote;
import flixel.group.FlxGroup.FlxTypedGroup;
import utils.UtilsData;
// song
import core.json.song.SongData.SongConfig;

class NoteController {
	public var isMiss:Bool = false;
	public var isSustain:Bool = false;
	// input good
	public var isGood:Bool = true;
	public var length:Float = 0;

	public var direction:Float = 0;

	public var noteSkinData:NoteSkinData;
	public var noteSkin:String = 'default';

	public var noteType:String = 'normal';

	public var strums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var note:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var sustains:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();

	public function new() {
		loadGenerateStrums();
	}

	public function loadGenerateStrums() {
		var noteDataPath:String = 'noteskins/$noteSkin/skin';
		noteSkinData = UtilsData.readJson(Paths.getPath('data/$noteDataPath', "json"));
	}

	public function generateNotes(SONG:SongConfig) {}

	public function destroy():Void {
		strums.destroy();
		note.destroy();
		sustains.destroy();

        strums = null;
        note = null;
        sustains = null;
	}
}

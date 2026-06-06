package game.controllers;

import core.json.objects.NoteSkinData;
import game.objects.sprites.notes.Note;
import game.objects.sprites.notes.NoteSustain;
import game.objects.sprites.notes.StrumNote;
import flixel.group.FlxGroup.FlxTypedGroup;
import game.graphics.shaders.hardcode.RGBShader;
import utils.UtilsData;
import game.PlayStateConfig;
// song
import core.rhythm.RhythmCore;
import core.json.song.SongData.SongConfig;
import core.json.engine.GlobalData.GlobalConfig;
import core.json.song.RatingData;

using Lambda;

class NoteController {
	public var isMiss:Bool = false;

	public var length:Float = 0;
	public var direction:Float = 0;

	public var noteSkinData:NoteSkinData;
	public var noteSkin:String = 'default';

	public var noteType:String = 'normal';

	public var strums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var sustains:FlxTypedGroup<NoteSustain> = new FlxTypedGroup<NoteSustain>();

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

	public var distanceRenderNotes:Float = 200;

	public var ratingData:RatingData;

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
		Trace.traceOnce("Created Strums");
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

		var ratingPath = Paths.getPath('data/ratings', 'json');
		ratingData = UtilsData.readJson(ratingPath);
		if (ratingData == null || ratingData.ratings == null)
			trace("WARNING: ratings.json not found or invalid");

		keys = noteSkinData.keys ?? 4;
		spacing = noteSkinData.spacing ?? 0;
		scrollSpeed = daSong.speed ?? 1.2;

		// splashes

		// hold splashes

		Trace.traceOnce("Note Skin JSON loaded");
	}

	public function loadGenerateStrums(x:Float, y:Float) {
		for (i in 0...keys) {
			var strum = new StrumNote(x + i * (112 + spacing), PlayStateConfig.strumLineY + y, noteSkinData.props, noteSkin);
			strum.playAnim('static' + i);
			RGBShader.applyFromSkin(strum, noteSkinData, i);
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

			if (isDownscroll && note.y > FlxG.height + distanceRenderNotes) {
				unspawnNotes.shift();
				note.destroy();
				continue;
			}

			if (note.strumTime - songTime < 2000) {
				if (Std.isOfType(note, NoteSustain))
					sustains.add(cast note);
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
			note.y = isDownscroll ? note.strum.y - ((note.strumTime - songTime) * scrollSpeed) : note.strum.y + ((note.strumTime - songTime) * scrollSpeed);

			if (note.y < -distanceRenderNotes && !isDownscroll)
				toDestroy.push(note);
			else if (note.y > FlxG.height + distanceRenderNotes && isDownscroll)
				toDestroy.push(note);
		}

		for (sustain in sustains.members) {
			if (sustain == null)
				continue;

			// body
			final strumCenterX = sustain.strum.x - sustain.strum.offset.x + sustain.strum.frameWidth * sustain.strum.scale.x * 0.5;
			sustain.x = strumCenterX - sustain.frameWidth * sustain.scale.x * 0.5;
			
			sustain.y = isDownscroll ? sustain.strum.y - ((sustain.strumTime - songTime) * scrollSpeed) : sustain.strum.y
				+ ((sustain.strumTime - songTime) * scrollSpeed);

			sustain.scale.y = (RhythmCore.stepInMs * (scrollSpeed * 0.45)) / sustain.frameHeight;
			sustain.offset.y = (sustain.scale.y * sustain.frameHeight - sustain.frameHeight) / 2;

			if (sustain.isHeld && sustain.strumTime <= songTime) {
				var halfStrum = sustain.strum.height * 0.5;
				var strumY = isDownscroll ? sustain.strum.y - halfStrum : sustain.strum.y + halfStrum;

				var clipY = (strumY - (sustain.y + sustain.offset.y)) / sustain.scale.y;
				clipY = Math.max(0, clipY);
				sustain.clipRect = new flixel.math.FlxRect(0, clipY, sustain.frameWidth, sustain.frameHeight - clipY);
			} else {
				sustain.clipRect = null;
			}

			// end
			if (sustain.isSustainEnd) {
				sustain.offset.y = 0;

				if (sustain.parentNote != null && sustain.parentNote.alive) {
					var body = sustain.parentNote;
					sustain.x = body.x;

					if (isDownscroll)
						sustain.y = body.y - sustain.height;
					else
						sustain.y = body.y + body.frameHeight * body.scale.y;

					sustain.alpha = (body.clipRect != null) ? 0 : 1;
				}

				if (sustain.parentNote == null || !sustain.parentNote.alive)
					toDestroy.push(sustain);

				continue;
			}

			if (sustain.strumTime + sustain.length < songTime)
				toDestroy.push(sustain);
			else if (sustain.y < -distanceRenderNotes && !isDownscroll)
				toDestroy.push(sustain);
			else if (sustain.y > FlxG.height + distanceRenderNotes && isDownscroll)
				toDestroy.push(sustain);
		}

		for (note in toDestroy)
			destroyNotes(note);
	}

	public function destroyNotes(note:Note) {
		if (Std.isOfType(note, NoteSustain))
			sustains.remove(cast note, true);
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
		if (daSong.songData == null) {
			Trace.traceOnce('ERROR songData null, generated 0 notes');
			return;
		}

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
			var note = new Note(data.time, keys, strum.x, 0, noteSkinData, noteSkin, data.lane);
			RGBShader.applyFromSkin(note, noteSkinData, data.lane);
			note.ID = globalLane;
			note.direction = globalLane;
			note.strumTime = data.time;
			note.mustPress = CharacterController.namesPlayer.contains(Reflect.field(charData, 'role'));
			if (!daSong.strumsVisible)
				note.visible = false;

			note.strum = strum;

			note.noteControl = this;

			note.noteType = data.type;

			if (data.length > 0) {
				var sustainTime = data.time + (RhythmCore.stepInMs * Math.round(data.length / RhythmCore.stepInMs));
				var sustain = new NoteSustain(sustainTime, keys, strum.x, 0, noteSkinData, noteSkin, data.lane, data.length, data.type, false);
				RGBShader.applyFromSkin(sustain, noteSkinData, data.lane);
				sustain.ID = globalLane;
				sustain.direction = globalLane;
				sustain.strumTime = sustainTime;
				sustain.mustPress = CharacterController.namesPlayer.contains(Reflect.field(charData, 'role'));
				sustain.noteControl = this;
				sustain.parentNote = sustain;
				sustain.strum = strum;
				sustain.noteType = data.type;
				if (isDownscroll)
					sustain.flipY = true;
				if (!daSong.strumsVisible)
					sustain.visible = false;
				unspawnNotes.push(sustain);

				// hold end
				var sustainEnd = new NoteSustain(data.length, keys, strum.x, 0, noteSkinData, noteSkin, data.lane, 0, data.type, true);
				RGBShader.applyFromSkin(sustainEnd, noteSkinData, data.lane);
				sustainEnd.ID = globalLane;
				sustainEnd.direction = globalLane;
				sustainEnd.strumTime = data.length;
				sustainEnd.mustPress = CharacterController.namesPlayer.contains(Reflect.field(charData, 'role'));
				sustainEnd.noteControl = this;
				sustainEnd.strum = strum;
				
				sustainEnd.noteType = data.type;
				if (isDownscroll)
					sustainEnd.flipY = true;
				if (!daSong.strumsVisible)
					sustainEnd.visible = false;
				unspawnNotes.push(sustainEnd);
			}
			unspawnNotes.push(note);
		}

		unspawnNotes.sort(sortNotes);
	}

	public function getHealthDrain(note:Note):Float {
		if (ratingData == null)
			return -0.04;

		var missRating = ratingData.ratings.find(r -> r.miss == true && r.window == null);
		return missRating != null ? missRating.health : -0.04;
	}

	public function getRatingForDiff(diff:Float):Null<RatingDataType> {
		if (ratingData == null)
			return null;

		var windowed = ratingData.ratings.filter(r -> r.window != null);
		windowed.sort((a, b) -> Std.int(a.window - b.window));

		for (r in windowed) {
			if (Math.abs(diff) <= r.window)
				return r;
		}
		return null;
	}

	public function getWorstWindow():Float {
		if (ratingData == null)
			return 166.0;
		var windows = ratingData.ratings.filter(r -> r.window != null).map(r -> r.window);
		return windows.length > 0 ? Lambda.fold(windows, Math.max, 0) : 166.0;
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

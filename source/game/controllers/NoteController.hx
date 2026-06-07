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

	// sustains limit clipping rect
	var _clipRect:flixel.math.FlxRect = new flixel.math.FlxRect();

	public var scrollSpeed:Float = 1.0;

	// configs
	public var isDownscroll:Bool = false;

	public var distanceRenderNotes:Float = 200;

	public var ratingData:RatingData;

	public var worstWindow:Float = 166.0;

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
		else {
			var best = 0.0;
			for (r in ratingData.ratings)
				if (r.window != null && r.window > best)
					best = r.window;
			worstWindow = best > 0 ? best : 166.0;
		}

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

			// note.alpha = 0.3;

			if (note.y + note.frameHeight * note.scale.y < 0 && !isDownscroll)
				toDestroy.push(note);
			else if (note.y > FlxG.height && isDownscroll)
				toDestroy.push(note);
		}

		for (sustain in sustains.members) {
			if (sustain == null || sustain.isSustainEnd)
				continue;

			// body
			final strumCenterX = sustain.strum.x - sustain.strum.offset.x + sustain.strum.frameWidth * sustain.strum.scale.x * 0.5;
			sustain.x = strumCenterX - sustain.frameWidth * sustain.scale.x * 0.5;

			sustain.origin.y = 0;

			var scaledHeight = sustain.length * scrollSpeed * 0.45;

			sustain.scale.y = scaledHeight / sustain.frameHeight;

			var strumY = isDownscroll ? sustain.strum.y - ((sustain.strumTime - songTime) * scrollSpeed) : sustain.strum.y
				+ ((sustain.strumTime - songTime) * scrollSpeed);
			var targetY = strumY + sustain.strum.frameHeight * 0.5;

			if (isDownscroll) {
				sustain.y = targetY - scaledHeight;
				sustain.flipY = true;
			} else {
				sustain.y = targetY;
				sustain.flipY = false;
			}
			sustain.offset.y = 0;

			if (sustain.isHeld && sustain.strumTime <= songTime) {
				var strumMidScreen = sustain.strum.y + sustain.strum.frameHeight * 0.5 - sustain.strum.offset.y;
				var clipY:Float;
				
				if (isDownscroll) {
					var bodyBottom = sustain.y + scaledHeight;
					clipY = sustain.frameHeight - (bodyBottom - strumMidScreen) / sustain.scale.y;
					clipY = Math.min(sustain.frameHeight, Math.max(0, clipY));
					_clipRect.set(0, 0, sustain.frameWidth, clipY);
				} else {
					clipY = (strumMidScreen - sustain.y) / sustain.scale.y;
					clipY = Math.max(0, clipY);
					_clipRect.set(0, clipY, sustain.frameWidth, sustain.frameHeight - clipY);
				}
				sustain.clipRect = _clipRect;
			} else {
				sustain.clipRect = null;
			}

			if (sustain.strumTime + sustain.length < songTime)
				toDestroy.push(sustain);
			else if (sustain.y + (sustain.length * scrollSpeed * 0.45) < 0 && !isDownscroll)
				toDestroy.push(sustain);
			else if (sustain.y - sustain.offset.y > FlxG.height && isDownscroll)
				toDestroy.push(sustain);
		}

		for (sustain in sustains.members) {
			if (sustain == null || !sustain.isSustainEnd)
				continue;
			var body = sustain.parentNote;

			if (body == null || toDestroy.contains(body)) {
				toDestroy.push(sustain);
				continue;
			}
			sustain.x = body.x;
			sustain.origin.y = 0;
			var bodyScaledHeight = body.frameHeight * body.scale.y;
			var endHeight = sustain.frameHeight * sustain.scale.y;
			if (isDownscroll) {
				sustain.flipY = true;
				sustain.y = body.y - endHeight;
			} else {
				sustain.flipY = false;
				sustain.y = body.y + bodyScaledHeight;
			}
			sustain.alpha = (body.clipRect != null && body.clipRect.height <= 0) ? 0 : 1;
		}

		for (note in toDestroy)
			if (!(note is NoteSustain))
				destroyNotes(note);
		// body sustains
		for (note in toDestroy)
			if ((note is NoteSustain) && !cast(note, NoteSustain).isSustainEnd)
				destroyNotes(note);
		// ends sustains
		for (note in toDestroy)
			if ((note is NoteSustain) && cast(note, NoteSustain).isSustainEnd)
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
				var sustain = new NoteSustain(data.time, keys, strum.x, 0, noteSkinData, noteSkin, data.lane, data.length, data.type, false);
				RGBShader.applyFromSkin(sustain, noteSkinData, data.lane);
				sustain.ID = globalLane;
				sustain.direction = globalLane;
				sustain.strumTime = data.time;
				sustain.mustPress = CharacterController.namesPlayer.contains(Reflect.field(charData, 'role'));
				sustain.noteControl = this;
				sustain.parentNote = null;
				sustain.strum = strum;
				sustain.noteType = data.type;
				if (isDownscroll)
					sustain.flipY = true;
				if (!daSong.strumsVisible)
					sustain.visible = false;
				unspawnNotes.push(sustain);

				// hold end
				var sustainEnd = new NoteSustain(data.time + data.length, keys, strum.x, 0, noteSkinData, noteSkin, data.lane, 0, data.type, true);
				RGBShader.applyFromSkin(sustainEnd, noteSkinData, data.lane);
				sustainEnd.ID = globalLane;
				sustainEnd.direction = globalLane;
				sustainEnd.strumTime = data.time + data.length;
				sustainEnd.mustPress = CharacterController.namesPlayer.contains(Reflect.field(charData, 'role'));
				sustainEnd.noteControl = this;
				sustainEnd.strum = strum;
				sustainEnd.parentNote = sustain;
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

	var _charStrumsCache:Map<String, Array<StrumNote>> = new Map();

	public function getCharStrums(charId:String):Array<StrumNote> {
		if (_charStrumsCache.exists(charId))
			return _charStrumsCache.get(charId);

		if (!charStrumOffsets.exists(charId)) {
			_charStrumsCache.set(charId, []);
			return [];
		}

		var offset:Int = charStrumOffsets.get(charId);
		var keys:Int = noteSkinData.keys ?? 4;
		var result:Array<StrumNote> = [];

		for (i in 0...keys) {
			var s = strums.members[offset + i];
			if (s != null)
				result.push(s);
		}
		_charStrumsCache.set(charId, result);
		return result;
	}

	function sortNotes(a:Note, b:Note):Int {
		var diff = a.strumTime - b.strumTime;
		if (diff != 0)
			return Std.int(diff);
		var aOrder = (a is NoteSustain) ? (cast(a, NoteSustain).isSustainEnd ? 2 : 1) : 0;
		var bOrder = (b is NoteSustain) ? (cast(b, NoteSustain).isSustainEnd ? 2 : 1) : 0;
		return aOrder - bOrder;
	}
}

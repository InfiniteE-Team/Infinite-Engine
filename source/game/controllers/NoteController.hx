package game.controllers;

import core.json.objects.NoteSkinData;
import game.objects.sprites.notes.Note;
import game.objects.sprites.notes.NoteSustain;
import game.objects.sprites.notes.StrumNote;
import flixel.group.FlxGroup.FlxTypedGroup;
import game.graphics.shaders.hardcode.RGBShader;
import utils.UtilsData;
import game.PlayStateConfig;
import flixel.tweens.FlxTween;
// song
import core.rhythm.RhythmCore;
import core.json.song.SongData.SongConfig;
import core.json.engine.GlobalData.GlobalConfig;
import core.json.song.RatingData;
#if HSCRIPT_ALLOWED
import core.scripting.ScriptHandler;
#end

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

	var _notePool:Map<String, Array<Note>> = new Map();

	var _sustainPool:Map<String, Array<NoteSustain>> = new Map();

	public var unspawnNotes:Array<Note> = [];

	public var charStrumOffsets:Map<String, Int> = new Map();

	var daSong:SongConfig = new SongConfig();
	var globalData:GlobalConfig;

	public var keys:Int = 4;

	var spacing:Float = 0;

	var input:InputController = new InputController();

	public var onMiss:Void->Void = null;

	// sustains limit clipping rect
	var _clipRect:flixel.math.FlxRect = new flixel.math.FlxRect();

	public var scrollSpeed:Float = 1.0;

	// configs
	public var isDownscroll:Bool = false;

	public var ratingData:RatingData;

	public var worstWindow:Float = 166.0;

	#if HSCRIPT_ALLOWED
	var scriptNC:ScriptHandler;
	#end

	public var playStateConfig:PlayStateConfig;

	public function new(daSong:SongConfig, isDownscroll:Bool, isGhostTapping:Bool, script:ScriptHandler, playStateConfig:PlayStateConfig) {
		this.daSong = daSong;
		this.isDownscroll = isDownscroll;
		input.isGhostTapping = isGhostTapping;
		this.playStateConfig = playStateConfig;
		loadJson();

		#if HSCRIPT_ALLOWED
		scriptNC = script;
		scriptNC.loadFolder('scripts/noteskins/$noteSkin/');
		#end

		for (i in 0...daSong.chars.length) {
			charStrumOffsets.set(daSong.chars[i].id, strums.length);

			var strumPos = daSong.chars[i].strumPos;
			loadGenerateStrums(strumPos != null ? strumPos[0] : 0, strumPos != null ? strumPos[1] : 0);
		}
		Trace.traceOnce("Created Strums");
	}

	public function loadJson() {
		globalData = core.ConfigMain.globalData;
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
			#if HSCRIPT_ALLOWED
			scriptNC.call("onBuildStrums", []);
			#end
			var strum = new StrumNote(x + i * (112 + spacing), PlayStateConfig.strumLineY + y, noteSkinData.props, noteSkin);
			strum.playAnim('static' + i);
			strum.applyShader(noteSkinData);
			if (!daSong.strumsVisible)
				strum.visible = false;
			if (isDownscroll)
				strum.y += 500;

			if (!playStateConfig.isStoryMode) {
				strum.alpha = 0;
				FlxTween.tween(strum, {alpha: 1}, 0.5, {startDelay: 0.5 + (0.2 * i)});
			}

			#if HSCRIPT_ALLOWED
			scriptNC.call("safeBuildStrums", []);
			#end

			strums.add(strum);

			#if HSCRIPT_ALLOWED
			scriptNC.call("postBuildStrums", []);
			#end
		}
	}

	public function update(songTime:Float) {
		updateNotes(songTime);
	}

	public function updateNotes(songTime:Float) {
		#if HSCRIPT_ALLOWED
		scriptNC.call("onNoteUpdate", [songTime]);
		#end

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

			#if HSCRIPT_ALLOWED
			if (scriptNC.callCancellable('onNoteMovementCancel', []))
				continue;
			#end

			note.x = note.strum.x;
			note.y = isDownscroll ? note.strum.y - ((note.strumTime - songTime) * scrollSpeed) : note.strum.y + ((note.strumTime - songTime) * scrollSpeed);

			// note.alpha = 0.3;

			#if HSCRIPT_ALLOWED
			scriptNC.call("onNoteMovement", [note, songTime]);
			#end

			if (note.tooLate && !note.wasMissed && !note.wasGoodHit) {
				note.wasMissed = true;
				note.alpha = 0.4;
				if (onMiss != null)
					onMiss();
			}

			if (!note.mustPress && note.wasGoodHit && !note.alive)
				toDestroy.push(note);

			if (note.y + note.frameHeight * note.scale.y < 0 && !isDownscroll)
				toDestroy.push(note);
			else if (note.y > FlxG.height && isDownscroll)
				toDestroy.push(note);
		}

		for (sustain in sustains.members) {
			if (sustain == null || sustain.isSustainEnd)
				continue;

			#if HSCRIPT_ALLOWED
			if (scriptNC.callCancellable('onSustainMovementCancel', []))
				continue;
			#end

			final strumCenterX = sustain.strum.x - sustain.strum.offset.x + sustain.strum.frameWidth * sustain.strum.scale.x * 0.5;
			sustain.x = strumCenterX - sustain.frameWidth * sustain.scale.x * 0.5;

			var scaledHeight = (sustain.length * scrollSpeed) + 1;

			var strumY = isDownscroll ? sustain.strum.y - ((sustain.strumTime - songTime) * scrollSpeed) : sustain.strum.y
				+ ((sustain.strumTime - songTime) * scrollSpeed);
			var targetY = strumY + sustain.strum.frameHeight * 0.5;

			if (isDownscroll) {
				sustain.y = targetY - scaledHeight;
			} else {
				sustain.y = targetY;
			}
			sustain.offset.y = 0;

			// clipping
			if (sustain.isHeld && sustain.strumTime <= songTime) {
				var strumMidScreen = sustain.strum.y + (sustain.strum.frameHeight * 0.5) - sustain.strum.offset.y;
				var clipY:Float;

				if (isDownscroll) {
					clipY = (strumMidScreen - sustain.y) / sustain.scale.y;
					clipY = Math.max(0, Math.min(sustain.frameHeight, clipY));
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

			#if HSCRIPT_ALLOWED
			scriptNC.call("onSustainMovement", [sustain, songTime]);
			#end

			if (sustain.strumTime + sustain.length < songTime)
				toDestroy.push(sustain);
			else if (sustain.y + scaledHeight < 0 && !isDownscroll)
				toDestroy.push(sustain);
			else if (sustain.y - sustain.offset.y > FlxG.height && isDownscroll)
				toDestroy.push(sustain);
		}

		// ends
		for (sustain in sustains.members) {
			if (sustain == null || !sustain.isSustainEnd)
				continue;

			#if HSCRIPT_ALLOWED
			if (scriptNC.callCancellable('onEndSustainMovementCancel', []))
				continue;
			#end

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

			var strumMidScreen = sustain.strum.y + (sustain.strum.frameHeight * 0.5) - sustain.strum.offset.y;

			if (isDownscroll) {
				sustain.alpha = (sustain.y >= strumMidScreen) ? 0 : 1;
			} else {
				sustain.alpha = ((sustain.y + endHeight) <= strumMidScreen) ? 0 : 1;
			}

			#if HSCRIPT_ALLOWED
			scriptNC.call("onEndSustainMovement", [songTime]);
			#end
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

		#if HSCRIPT_ALLOWED
		scriptNC.call("postNoteUpdate", [songTime]);
		#end
	}

	public function destroyNotes(note:Note) {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onDestroyNotesCancel', []))
			return;
		#end

		if (Std.isOfType(note, NoteSustain)) {
			sustains.remove(cast note, true);
			note.kill();
			if (!_sustainPool.exists(note.noteSkin))
				_sustainPool.set(note.noteSkin, []);
			_sustainPool.get(note.noteSkin).push(cast note);
		} else {
			notes.remove(note, true);
			note.kill();
			if (!_notePool.exists(note.noteSkin))
				_notePool.set(note.noteSkin, []);
			_notePool.get(note.noteSkin).push(note);
		}

		#if HSCRIPT_ALLOWED
		scriptNC.call("onDestroyNotes", []);
		#end
	}

	public function getHittableNote(charId:String, dir:Int, mustPress:Bool = true):Note {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onHittableNoteCancel', []))
			return null;
		#end

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
			Trace.traceOnce('songData null, generated 0 notes', true);
			return;
		}

		#if HSCRIPT_ALLOWED
		scriptNC.call("onGenerateNotes", []);
		#end

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
			var skinForChar = charData.noteSkin ?? noteSkin;
			var pool = _notePool.get(skinForChar);

			var note:Note;
			if (pool != null && pool.length > 0) {
				note = pool.pop();
				note.revive();
				note.reinit(data.time, keys, strum.x, 0, noteSkinData, skinForChar, data.lane);
			} else {
				note = new Note(data.time, keys, strum.x, 0, noteSkinData, skinForChar, data.lane);
			}

			note.ID = globalLane;
			note.direction = globalLane;
			note.strumTime = data.time;
			note.mustPress = CharacterController.namesPlayer.contains(charData.role);
			if (!daSong.strumsVisible)
				note.visible = false;

			note.strum = strum;

			note.noteControl = this;

			note.noteType = data.type;

			#if HSCRIPT_ALLOWED
			scriptNC.call("onGenerateNote", []);
			#end

			if (data.length > 0) {
				var skinForChar = charData.noteSkin ?? noteSkin;
				var pool = _sustainPool.get(skinForChar);

				var totalLength:Float = data.length;
				var curLength:Float = 0;
				var lastSustain:NoteSustain = null;

				while (curLength < totalLength) {
					var isEndSegment = (curLength + RhythmCore.stepInMs >= totalLength);
					var segmentLength = isEndSegment ? (totalLength - curLength) : RhythmCore.stepInMs;
					var sustainTime = data.time + curLength;

					var sustain:NoteSustain;
					if (pool != null && pool.length > 0) {
						sustain = pool.pop();
						sustain.revive();
						sustain.reinitSustain(sustainTime, keys, strum.x, 0, noteSkinData, skinForChar, data.lane, segmentLength, data.type, false);
					} else {
						sustain = new NoteSustain(sustainTime, keys, strum.x, 0, noteSkinData, skinForChar, data.lane, segmentLength, data.type, false);
					}

					sustain.ID = globalLane;
					sustain.direction = globalLane;
					sustain.strumTime = sustainTime;
					sustain.mustPress = CharacterController.namesPlayer.contains(charData.role);
					sustain.noteControl = this;
					sustain.strum = strum;
					sustain.noteType = data.type;
					if (isDownscroll)
						sustain.flipY = true;
					if (!daSong.strumsVisible)
						sustain.visible = false;

					sustain.origin.y = 0;
					var scaledHeight = (sustain.length * scrollSpeed) + 1;
					sustain.scale.y = scaledHeight / sustain.frameHeight;

					#if HSCRIPT_ALLOWED
					scriptNC.call("onGenerateSustain", []);
					#end

					unspawnNotes.push(sustain);
					lastSustain = sustain;

					curLength += RhythmCore.stepInMs;
				}

				// end
				if (lastSustain != null) {
					var sustainEnd:NoteSustain;
					if (pool != null && pool.length > 0) {
						sustainEnd = pool.pop();
						sustainEnd.revive();
						sustainEnd.reinitSustain(data.time + data.length, keys, strum.x, 0, noteSkinData, skinForChar, data.lane, 0, data.type, true);
					} else {
						sustainEnd = new NoteSustain(data.time + data.length, keys, strum.x, 0, noteSkinData, skinForChar, data.lane, 0, data.type, true);
					}

					sustainEnd.ID = globalLane;
					sustainEnd.direction = globalLane;
					sustainEnd.strumTime = data.time + data.length;
					sustainEnd.mustPress = CharacterController.namesPlayer.contains(Reflect.field(charData, 'role'));
					sustainEnd.noteControl = this;
					sustainEnd.strum = strum;
					sustainEnd.parentNote = lastSustain;
					sustainEnd.noteType = data.type;
					if (isDownscroll)
						sustainEnd.flipY = true;
					if (!daSong.strumsVisible)
						sustainEnd.visible = false;

					sustainEnd.origin.y = 0;

					#if HSCRIPT_ALLOWED
					scriptNC.call("onGenerateEndSustain", []);
					#end

					unspawnNotes.push(sustainEnd);
				}
			}
			unspawnNotes.push(note);
		}

		#if HSCRIPT_ALLOWED
		scriptNC.call("postGenerateNotes", []);
		#end

		unspawnNotes.sort(sortNotes);
	}

	public function getHealthDrain(note:Note):Float {
		if (ratingData == null)
			return -0.04;

		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onHealthDrainCancel', []))
			return 0.0;
		#end

		var missRating = ratingData.ratings.find(r -> r.miss == true && r.window == null);
		return missRating != null ? missRating.health : -0.04;
	}

	public function getMissScore():Int {
		if (ratingData == null)
			return -10;

		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onMissScoreCancel', []))
			return 0;
		#end

		var missRating = ratingData.ratings.find(r -> r.miss == true && r.window == null);
		return missRating != null ? missRating.score : -10;
	}

	public function getRatingForDiff(diff:Float):Null<RatingDataType> {
		if (ratingData == null)
			return null;

		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onRatingDiffCancel', []))
			return null;
		#end

		var windowed = ratingData.ratings.filter(r -> r.window != null);
		windowed.sort((a, b) -> Std.int(a.window - b.window));

		for (r in windowed) {
			if (Math.abs(diff) <= r.window)
				return r;
		}
		return null;
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
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onGetCharStrumsCancel', []))
			return [];
		#end

		if (_charStrumsCache.exists(charId))
			return _charStrumsCache.get(charId);

		#if HSCRIPT_ALLOWED
		scriptNC.call("onGetCharStrums", []);
		#end

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
		#if HSCRIPT_ALLOWED
		scriptNC.call("postGetCharStrums", []);
		#end

		return result;
	}

	function sortNotes(a:Note, b:Note):Int {
		#if HSCRIPT_ALLOWED
		scriptNC.call("onSortNotes", []);
		#end

		var diff = a.strumTime - b.strumTime;
		var result:Int;

		if (diff != 0)
			result = Std.int(diff);
		else {
			var aOrder = (a is NoteSustain) ? (cast(a, NoteSustain).isSustainEnd ? 2 : 1) : 0;
			var bOrder = (b is NoteSustain) ? (cast(b, NoteSustain).isSustainEnd ? 2 : 1) : 0;
			result = aOrder - bOrder;
		}

		#if HSCRIPT_ALLOWED
		scriptNC.call("postSortNotes", []);
		#end
		return result;
	}
}

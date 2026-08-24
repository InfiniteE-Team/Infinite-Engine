package game.controllers;

import game.PlayStateConfig;
import flixel.tweens.FlxTween;
// song
import core.json.song.SongData.SongConfig;
import core.json.engine.GlobalData.GlobalConfig;
import core.json.song.RatingData;
// notes
import core.json.objects.NoteSkinData;
import game.objects.sprites.notes.*;
import flixel.group.FlxGroup.FlxTypedGroup;
import game.graphics.shaders.hardcode.RGBShader;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

class NoteController {
	public var isMiss:Bool = false;

	public var length:Float = 0;
	public var direction:Float = 0;

	public var noteSkinData:NoteSkinData;
	public var splashesSkinData:NoteSkinData;
	public var holdSkinData:NoteSkinData;

	public var noteSkin:String = 'default';
	public var noteType:String = 'normal';

	public var blackBacks:FlxTypedGroup<flixel.FlxSprite> = new FlxTypedGroup<flixel.FlxSprite>();
	public var strums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var sustains:FlxTypedGroup<NoteSustain> = new FlxTypedGroup<NoteSustain>();
	public var splashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();
	public var holdsplashes:FlxTypedGroup<HoldSplash> = new FlxTypedGroup<HoldSplash>();

	public var activeOpponentHolds:Map<Int, Bool> = new Map();

	public var strumsByChar:Map<String, FlxTypedGroup<StrumNote>> = new Map();

	var _notePool:Map<String, Array<Note>> = new Map();
	var _sustainPool:Map<String, Array<NoteSustain>> = new Map();
	var _splashPool:Map<String, Array<NoteSplash>> = new Map();
	var _holdsplashPool:Map<String, Array<HoldSplash>> = new Map();

	var _charNotesVisible:Map<String, Bool> = new Map();

	public var unspawnNotes:Array<Note> = [];
	public var charStrumOffsets:Map<String, Int> = new Map();

	var daSong:SongConfig = new SongConfig();
	var globalData:GlobalConfig;

	public var keys:Int = 4;

	var spacing:Float = 0;
	var input:InputController = new InputController();

	// sustains limit clipping rect
	var _clipRect:flixel.math.FlxRect = new flixel.math.FlxRect();

	// scrollspeed
	public var scrollSpeed:Float = 1.0;
	public var targetScrollSpeed:Float = 1.0;
	public var lerpSpeed:Float = 5.0;

	// configs
	public var isDownscroll:Bool = false;
	public var ratingData:RatingData;
	public var worstWindow:Float = 166.0;

	// CACHED DATA FOR OPTIMIZATION
	var _cachedRatings:Array<Dynamic> = [];
	var _cachedMissHealth:Float = -0.04;
	var _cachedMissScore:Int = -10;

	#if HSCRIPT_ALLOWED
	var scriptNC:ScriptHandler;
	#end

	public var playStateConfig:PlayStateConfig;
	public var gameAudio:core.rhythm.audio.GameAudio;

	// config
	var strumsVisible:Bool = true;
	var notesVisible:Bool = true;

	public function new(daSong:SongConfig, isDownscroll:Bool, isGhostTapping:Bool, script:ScriptHandler, playStateConfig:PlayStateConfig,
			gameAudio:core.rhythm.audio.GameAudio) {
		this.daSong = daSong;
		this.isDownscroll = isDownscroll;
		input.isGhostTapping = isGhostTapping;
		this.playStateConfig = playStateConfig;
		this.gameAudio = gameAudio;

		loadJson();

		#if HSCRIPT_ALLOWED
		scriptNC = script;
		scriptNC.loadFolder('scripts/noteskins/$noteSkin/');
		#end

		for (i in 0...daSong.chars.length) {
			charStrumOffsets.set(daSong.chars[i].id, strums.length);

			var strumPos = daSong.chars[i].strums.position;
			var isPlayer = CharacterController.namesPlayer.contains(daSong.chars[i].role);
			var charData = daSong.chars[i];
			strumsVisible = charData?.strums?.visible ?? true;
			notesVisible = charData?.strums?.notesVisible ?? strumsVisible;

			var bg = bglaneBackdrop(strumPos != null ? strumPos[0] : 0);
			bg.visible = strumsVisible && notesVisible;
			blackBacks.add(bg);

			loadGenerateStrums(strumPos != null ? strumPos[0] : 0, strumPos != null ? strumPos[1] : 0, daSong.chars[i].id, isPlayer);
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
		noteSkinData = FormatJson.readJson(Paths.getPath('data/$noteDataPath', "json"));

		var ratingPath = Paths.getPath('data/ratings', 'json');
		ratingData = FormatJson.readJson(ratingPath);

		if (ratingData == null || ratingData.ratings == null) {
			trace("WARNING: ratings.json not found or invalid");
		} else {
			var best = 0.0;
			_cachedRatings = []; // Reset cached ratings

			for (rating in ratingData.ratings) {
				// Cache best window
				if (rating.window != null && rating.window > best)
					best = rating.window;

				// Cache hit windows array directly for fast checks
				if (rating.window != null) {
					_cachedRatings.push(rating);
				}
				// Cache misses stats once to avoid Lambda searches on every miss
				else if (rating.miss == true) {
					_cachedMissHealth = rating.health;
					_cachedMissScore = rating.score;
				}
			}

			// Sort cached hit ratings once at startup, instead of during gameplay
			_cachedRatings.sort((a, b) -> (a.window < b.window) ? -1 : (a.window > b.window ? 1 : 0));
			worstWindow = best > 0 ? best : 166.0;
		}

		keys = noteSkinData.keys ?? 4;
		spacing = noteSkinData.spacing ?? 0;
		scrollSpeed = daSong.speed ?? 1.2;
		targetScrollSpeed = scrollSpeed;

		// splashes
		var splashesDataPath:String = 'noteskins/$noteSkin/splashes';
		splashesSkinData = FormatJson.readJson(Paths.getPath('data/$splashesDataPath', "json"));

		// hold splashes
		var holdDataPath:String = 'noteskins/$noteSkin/holdsplashes';
		holdSkinData = FormatJson.readJson(Paths.getPath('data/$holdDataPath', "json"));

		Trace.traceOnce("Note Skin JSON loaded");
	}

	public function bglaneBackdrop(x:Float):flixel.FlxSprite {
		var strumWidth:Float = (keys * 112) + (spacing * (keys - 1)) + 45;
		var back:flixel.FlxSprite = new flixel.FlxSprite(x, 0).makeGraphic(Std.int(strumWidth), FlxG.height, flixel.util.FlxColor.BLACK);
		var alphaVal:Float = SaveData.data.laneBackdrop;
		back.alpha = (alphaVal > 1) ? (alphaVal / 100) : alphaVal;
		return back;
	}

	public function loadGenerateStrums(x:Float, y:Float, charId:String, isPlayer:Bool) {
		if (!strumsByChar.exists(charId)) {
			strumsByChar.set(charId, new FlxTypedGroup<StrumNote>());
		}
		var charGroup = strumsByChar.get(charId);

		var charData = Lambda.find(daSong.chars, c -> c.id == charId);

		_charNotesVisible.set(charId, notesVisible);

		for (i in 0...keys) {
			#if HSCRIPT_ALLOWED
			scriptNC.call("onBuildStrums", []);
			#end
			var strum = new StrumNote(x + i * (112 + spacing), PlayStateConfig.strumLineY + y, noteSkinData.props, noteSkin);
			strum.playAnim('static' + i);
			strum.applyShader(noteSkinData);
			if (isDownscroll)
				strum.y += 500;

			if (SaveData.data.middlescroll) {
				if (isPlayer)
					strum.x = ((FlxG.width - ((keys * 112) + ((keys - 1) * spacing))) / 2) + i * (112 + spacing);
				else
					strum.visible = false;
			}

			if (!PlayStateConfig.isStoryMode) {
				strum.alpha = 0;
				strum.y -= 10;
				FlxTween.tween(strum, {alpha: 1, y: strum.y + 10}, 0.5, {startDelay: 0.5 + (0.2 * i)});
			}

			#if HSCRIPT_ALLOWED
			scriptNC.call("safeBuildStrums", []);
			#end

			strum.visible = strumsVisible;

			strums.add(strum);
			charGroup.add(strum);

			#if HSCRIPT_ALLOWED
			scriptNC.call("postBuildStrums", []);
			#end
		}
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

		// FAST LOOKUP: Create a map of characters to avoid Lambda.find in the main loop
		var charMap:Map<String, Dynamic> = new Map();
		for (c in daSong.chars) {
			charMap.set(c.id, c);
		}

		for (data in daSong.songData.notes) {
			var charData = charMap.get(data.char);
			if (charData == null)
				continue;

			var offset = charStrumOffsets.get(charData.id);
			if (offset == null)
				continue;

			var globalLane = offset + data.lane;
			var strum = strums.members[globalLane];
			if (strum == null)
				continue;

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

			var notesVis = _charNotesVisible.get(charData.id) ?? true;
			note.visible = notesVis;

			note.strum = strum;
			note.noteControl = this;
			note.noteType = data.type;

			#if HSCRIPT_ALLOWED
			scriptNC.call("onGenerateNote", []);
			#end

			if (data.length > 0) {
				var sustainPool = _sustainPool.get(skinForChar);
				var totalLength:Float = data.length;

				var sustain:NoteSustain;
				if (sustainPool != null && sustainPool.length > 0) {
					sustain = sustainPool.pop();
					sustain.revive();
					sustain.reinitSustain(data.time, keys, strum.x, 0, noteSkinData, skinForChar, data.lane, totalLength, data.type, false);
				} else {
					sustain = new NoteSustain(data.time, keys, strum.x, 0, noteSkinData, skinForChar, data.lane, totalLength, data.type, false);
				}

				sustain.ID = globalLane;
				sustain.direction = globalLane;
				sustain.strumTime = data.time;
				sustain.mustPress = note.mustPress;
				sustain.noteControl = this;
				sustain.strum = strum;
				sustain.noteType = data.type;
				if (isDownscroll)
					sustain.flipY = true;
				sustain.visible = notesVis;

				sustain.origin.y = 0;
				// Just for initial scale, we will recalculate on update anyway
				sustain.scale.y = (totalLength * 0.45 * scrollSpeed) / sustain.frameHeight;

				#if HSCRIPT_ALLOWED
				scriptNC.call("onGenerateSustain", []);
				#end

				unspawnNotes.push(sustain);

				// end sustain
				var sustainEnd:NoteSustain;
				if (sustainPool != null && sustainPool.length > 0) {
					sustainEnd = sustainPool.pop();
					sustainEnd.revive();
					sustainEnd.reinitSustain(data.time + data.length, keys, strum.x, 0, noteSkinData, skinForChar, data.lane, 0, data.type, true);
				} else {
					sustainEnd = new NoteSustain(data.time + data.length, keys, strum.x, 0, noteSkinData, skinForChar, data.lane, 0, data.type, true);
				}

				sustainEnd.ID = globalLane;
				sustainEnd.direction = globalLane;
				sustainEnd.strumTime = data.time;
				sustainEnd.mustPress = note.mustPress;
				sustainEnd.noteControl = this;
				sustainEnd.strum = strum;
				sustainEnd.parentNote = sustain;
				sustainEnd.noteType = data.type;
				if (isDownscroll)
					sustainEnd.flipY = true;
				sustainEnd.visible = notesVis;
				sustainEnd.origin.y = 0;

				#if HSCRIPT_ALLOWED
				scriptNC.call("onGenerateEndSustain", []);
				#end

				unspawnNotes.push(sustainEnd);
			}
			unspawnNotes.push(note);
		}

		#if HSCRIPT_ALLOWED
		scriptNC.call("postGenerateNotes", []);
		#end

		#if HSCRIPT_ALLOWED
		scriptNC.call("onSortNotes", []);
		#end
		unspawnNotes.sort(sortNotes);
		#if HSCRIPT_ALLOWED
		scriptNC.call("postSortNotes", []);
		#end
	}

	public function spawnSplash(strum:StrumNote, direction:Int, noteType:String = 'normal'):Void {
		var pool = _splashPool.get(noteSkin);
		var splash:NoteSplash;

		if (pool != null && pool.length > 0) {
			splash = pool.pop();
			splash.revive();
		} else {
			splash = new NoteSplash(keys, strum.x, strum.y, splashesSkinData, noteSkin, direction, noteType);
		}

		splash.random = Std.int(Math.random() * 2);
		splash.direction = direction;
		splash.noteControl = this;
		splash.setPosition(strum.x, strum.y);
		splash.loadSprite(splashesSkinData);
		splashes.add(splash);
	}

	public function recycleSplash(splash:NoteSplash):Void {
		splashes.remove(splash, true);
		splash.kill();
		splash.noteControl = null;
		if (!_splashPool.exists(splash.noteSkin))
			_splashPool.set(splash.noteSkin, []);
		_splashPool.get(splash.noteSkin).push(splash);
	}

	public var activeHoldSplashes:Map<StrumNote, HoldSplash> = new Map();

	public function spawnHoldSplash(strum:StrumNote, direction:Int, noteType:String = 'normal'):Void {
		if (activeHoldSplashes.exists(strum))
			return;

		var pool = _holdsplashPool.get(noteSkin);
		var holdsplash:HoldSplash;

		if (pool != null && pool.length > 0) {
			holdsplash = pool.pop();
			holdsplash.revive();
		} else {
			holdsplash = new HoldSplash(keys, strum.x + strum.offset.x, strum.y + strum.offset.y, holdSkinData, noteSkin, direction, noteType);
		}

		holdsplash.direction = direction;
		holdsplash.noteControl = this;
		holdsplash.setPosition(strum.x, strum.y);
		holdsplash.loadSprite(holdSkinData);
		holdsplashes.add(holdsplash);

		activeHoldSplashes.set(strum, holdsplash);
	}

	public function stopHoldSplash(strum:StrumNote):Void {
		var holdsplash = activeHoldSplashes.get(strum);
		if (holdsplash != null) {
			holdsplash.endHold();
			activeHoldSplashes.remove(strum);
		}
	}

	public function recycleHoldSplash(holdsplash:HoldSplash):Void {
		holdsplashes.remove(holdsplash, true);
		holdsplash.kill();
		holdsplash.noteControl = null;

		for (strum in activeHoldSplashes.keys()) {
			if (activeHoldSplashes.get(strum) == holdsplash) {
				activeHoldSplashes.remove(strum);
				break;
			}
		}

		if (!_holdsplashPool.exists(holdsplash.noteSkin))
			_holdsplashPool.set(holdsplash.noteSkin, []);
		_holdsplashPool.get(holdsplash.noteSkin).push(holdsplash);
	}

	public function update(songTime:Float) {
		scrollSpeed = flixel.math.FlxMath.lerp(scrollSpeed, targetScrollSpeed, flixel.FlxG.elapsed * lerpSpeed);
		updateNotes(songTime);
	}

	var toDestroy:Array<Note> = [];
	var toDestroySet:Map<Note, Bool> = new Map();

	public function updateNotes(songTime:Float) {
		#if HSCRIPT_ALLOWED
		scriptNC.call("onNoteUpdate", [songTime]);
		#end

		while (unspawnNotes.length > 0) {
			var note = unspawnNotes[0];
			var isSustain = (note is NoteSustain);
			var spawnTime = note.strumTime;

			if (isSustain && cast(note, NoteSustain).isSustainEnd && cast(note, NoteSustain).parentNote != null) {
				spawnTime = cast(note, NoteSustain).parentNote.strumTime;
			}

			if (spawnTime - songTime < 2000) {
				note.visible = daSong.strumsVisible && note.strum.visible;
				if (isSustain)
					sustains.add(cast note);
				else
					notes.add(note);
				unspawnNotes.shift();
			} else {
				break;
			}
		}

		toDestroy.resize(0);
		toDestroySet.clear();
		activeOpponentHolds.clear();

		var scrollMult = 0.45 * scrollSpeed;

		for (note in notes.members) {
			if (note == null)
				continue;

			#if HSCRIPT_ALLOWED
			if (scriptNC.callCancellable('onNoteMovementCancel', []))
				continue;
			#end

			note.x = note.strum.x;
			var timeDiff = note.strumTime - songTime;

			if (isDownscroll)
				note.y = note.strum.y - (timeDiff * scrollMult);
			else
				note.y = note.strum.y + (timeDiff * scrollMult);

			#if HSCRIPT_ALLOWED
			scriptNC.call("onNoteMovement", [note, songTime]);
			#end

			if (note.tooLate && !note.wasMissed && !note.wasGoodHit) {
				note.wasMissed = true;
				note.alpha = 0.4;
				input.onMiss(playStateConfig, this, gameAudio);
			}

			if (!note.mustPress && note.wasGoodHit && !note.alive) {
				toDestroy.push(note);
				toDestroySet.set(note, true);
			}

			if (!isDownscroll && note.y + note.frameHeight * note.scale.y < 0) {
				if (note.mustPress && !note.wasGoodHit && !note.wasMissed) {
					note.wasMissed = true;
					note.alpha = 0.4;
					input.onMiss(playStateConfig, this, gameAudio);
				}
				toDestroy.push(note);
				toDestroySet.set(note, true);
			} else if (isDownscroll && note.y > flixel.FlxG.height) {
				if (note.mustPress && !note.wasGoodHit && !note.wasMissed) {
					note.wasMissed = true;
					note.alpha = 0.4;
					input.onMiss(playStateConfig, this, gameAudio);
				}
				toDestroy.push(note);
				toDestroySet.set(note, true);
			}
		}

		for (sustain in sustains.members) {
			if (sustain == null)
				continue;

			var lane = sustain.direction;

			// CPU HOLD SPLASHES
			if (!SaveData.data.middlescroll) {
				if (!sustain.mustPress) {
					var isWithinHold = songTime >= sustain.strumTime && songTime <= (sustain.strumTime + sustain.length);
					if (isWithinHold) {
						if (!sustain.isHeld) {
							sustain.isHeld = true;
							spawnHoldSplash(sustain.strum, lane % keys, sustain.noteType);
						}
						sustain.strum.playAnim('confirm' + (lane % keys), false);
						activeOpponentHolds.set(lane, true);
					} else if (sustain.isHeld) {
						sustain.isHeld = false;
						stopHoldSplash(sustain.strum);
						sustain.strum.playAnim('static' + (lane % keys), true);
						activeOpponentHolds.remove(lane);
					}
				}
			}
			
			// HANDLE SUSTAIN ENDS
			if (sustain.isSustainEnd) {
				#if HSCRIPT_ALLOWED
				if (scriptNC.callCancellable('onEndSustainMovementCancel', []))
					continue;
				#end

				var body = sustain.parentNote;
				if (body == null || toDestroySet.exists(body)) {
					toDestroy.push(sustain);
					toDestroySet.set(sustain, true);
					continue;
				}

				sustain.x = body.x;
				sustain.origin.y = 0;

				var endHeight = sustain.frameHeight * sustain.scale.y;
				if (isDownscroll) {
					sustain.flipY = true;
					sustain.y = body.y - endHeight;
				} else {
					sustain.flipY = false;
					sustain.y = body.y + (body.frameHeight * body.scale.y);
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
				continue;
			}

			// HANDLE NORMAL SUSTAINS (BODIES)
			#if HSCRIPT_ALLOWED
			if (scriptNC.callCancellable('onSustainMovementCancel', []))
				continue;
			#end

			var strumCenterX = sustain.strum.x - sustain.strum.offset.x + sustain.strum.frameWidth * sustain.strum.scale.x * 0.5;
			sustain.x = strumCenterX - sustain.frameWidth * sustain.scale.x * 0.5;

			var scaledHeight:Float;
			var strumMid = sustain.strum.y + (sustain.strum.frameHeight * 0.5) - (sustain.strum.offset.y * 1.45);

			if (sustain.isHeld && sustain.strumTime <= songTime) {
				var remaining = Math.max(0, (sustain.strumTime + sustain.length) - songTime);
				scaledHeight = remaining * scrollMult;
				sustain.scale.y = scaledHeight / sustain.frameHeight;

				sustain.y = isDownscroll ? (strumMid - scaledHeight) : strumMid;
			} else {
				scaledHeight = sustain.length * scrollMult;
				sustain.scale.y = scaledHeight / sustain.frameHeight;

				var timeDiff = sustain.strumTime - songTime;
				var strumY = isDownscroll ? (sustain.strum.y - (timeDiff * scrollMult)) : (sustain.strum.y + (timeDiff * scrollMult));
				var targetY = strumY + sustain.strum.frameHeight * 0.5;

				sustain.y = isDownscroll ? (targetY - scaledHeight) : targetY;
			}

			sustain.offset.y = 0;
			sustain.clipRect = null;

			#if HSCRIPT_ALLOWED
			scriptNC.call("onSustainMovement", [sustain, songTime]);
			#end

			if (sustain.strumTime + sustain.length < songTime) {
				if (sustain.isHeld) {
					sustain.isHeld = false;
					stopHoldSplash(sustain.strum);
				}
				toDestroy.push(sustain);
				toDestroySet.set(sustain, true);
			} else if (!isDownscroll && sustain.y + scaledHeight < 0) {
				toDestroy.push(sustain);
				toDestroySet.set(sustain, true);
			} else if (isDownscroll && sustain.y - sustain.offset.y > flixel.FlxG.height) {
				toDestroy.push(sustain);
				toDestroySet.set(sustain, true);
			}
		}

		for (note in toDestroy) {
			destroyNotes(note);
		}

		#if HSCRIPT_ALLOWED
		scriptNC.call("postNoteUpdate", [songTime]);
		#end
	}

	public function destroyNotes(note:Note) {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onDestroyNotesCancel', []))
			return;
		#end

		if ((note is NoteSustain)) {
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

	public function getHealthDrain(note:Note):Float {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onHealthDrainCancel', []))
			return 0.0;
		#end
		return _cachedMissHealth;
	}

	public function getMissScore():Int {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onMissScoreCancel', []))
			return 0;
		#end
		return _cachedMissScore;
	}

	public function getRatingForDiff(diff:Float):Null<Dynamic> {
		if (_cachedRatings.length == 0)
			return null;

		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onRatingDiffCancel', []))
			return null;
		#end

		var absDiff = Math.abs(diff);
		for (r in _cachedRatings) {
			if (absDiff <= r.window)
				return r;
		}
		return null;
	}

	var _charStrumsCache:Map<String, Array<StrumNote>> = new Map();

	public function destroy():Void {
		for (pool in _notePool)
			for (n in pool)
				n.destroy();
		for (pool in _sustainPool)
			for (n in pool)
				n.destroy();

		_notePool = null;
		_sustainPool = null;
		_charStrumsCache = null;
		_cachedRatings = null;

		strums.destroy();
		activeOpponentHolds = null;

		for (group in strumsByChar)
			group.destroy();
		strumsByChar = null;

		notes.destroy();
		sustains.destroy();
		splashes.destroy();
		holdsplashes.destroy();

		strums = null;
		notes = null;
		sustains = null;
		splashes = null;
		holdsplashes = null;
	}

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
		if (a.strumTime < b.strumTime)
			return -1;
		if (a.strumTime > b.strumTime)
			return 1;
		var aOrder = (a is NoteSustain) ? (cast(a, NoteSustain).isSustainEnd ? 2 : 1) : 0;
		var bOrder = (b is NoteSustain) ? (cast(b, NoteSustain).isSustainEnd ? 2 : 1) : 0;
		return aOrder - bOrder;
	}
}

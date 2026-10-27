package game.controllers;

import game.objects.sprites.notes.NoteSkins;
import game.PlayStateConfig;
import core.json.song.SongData.NoteData;
import core.json.song.SongData.SongConfig;
import core.json.engine.GlobalData.GlobalConfig;
import core.json.song.RatingData;
import core.json.objects.NoteSkinData;
import game.objects.sprites.notes.*;
import flixel.group.FlxGroup.FlxTypedGroup;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

class NoteController {
	public var strumlines:Array<Strumline> = [];

	var strumsByChar:Map<String, Strumline> = new Map();

	public var blackBacks:FlxTypedGroup<flixel.FlxSprite> = new FlxTypedGroup<flixel.FlxSprite>();
	public var strums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var sustains:FlxTypedGroup<NoteSustain> = new FlxTypedGroup<NoteSustain>();
	public var splashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();
	public var holdsplashes:FlxTypedGroup<HoldSplash> = new FlxTypedGroup<HoldSplash>();

	public var charStrumOffsets:Map<String, Int> = new Map();

	public var activeOpponentHolds:Map<Int, Bool> = new Map();

	// skin and rating
	public var noteSkin:String = 'default';
	public var noteSkinData:NoteSkinData;
	public var splashesSkinData:NoteSkinData;
	public var holdSkinData:NoteSkinData;
	public var popupsData:Dynamic = null;
	public var noteType:String = 'normal';
	public var ratingData:RatingData;
	public var worstWindow:Float = 166.0;

	var _skinParts:Map<String, Dynamic> = new Map();
	var cachedRatings:Array<Dynamic> = [];
	var cachedMissHealth:Float = -0.04;
	var cachedMissScore:Int = -10;
	var _noteTypeCache:Map<String, core.json.objects.NoteTypeData> = new Map();

	var daSong:SongConfig = new SongConfig();
	var globalData:GlobalConfig;
	var charMap:Map<String, Dynamic> = new Map();

	var rawNotes:Array<NoteData> = [];
	var rawNoteIndex:Int = 0;

	public var unspawnNotes:Array<Note> = [];

	var _noteSpawnIndex:Int = 0;
	var toDestroySet:Map<Note, Bool> = new Map();

	static inline var GENERATE_AHEAD_MS:Float = 8000.0;

	public var scrollSpeed:Float = 1.0;
	public var targetScrollSpeed:Float = 1.0;

	var scrollTween:flixel.tweens.FlxTween;

	// config
	public var keys:Int = 4;
	public var isDownscroll:Bool = false;
	public var isMiddlescroll:Bool = false;
	public var noteTypeManager:NoteTypeManager;
	public var charController:CharacterController = null;
	public var playStateConfig:PlayStateConfig;
	public var gameAudio:core.rhythm.audio.GameAudio;
	public var isMiss:Bool = false;

	final POOL_LENGTH:Int = 48;
	var confirmAnims:Array<String> = [];
	var staticAnims:Array<String> = [];

	var strumsGlobalOffset:Map<Strumline, Int> = new Map();

	#if HSCRIPT_ALLOWED
	var scriptNC:ScriptHandler;
	#end

	public var input(get, never):game.controllers.InputController;

	function get_input():game.controllers.InputController {
		for (sl in strumlines)
			if (sl.isPlayer)
				return sl.input;
		return strumlines.length > 0 ? strumlines[strumlines.length - 1].input : new game.controllers.InputController();
	}

	public function new(daSong:SongConfig, isDownscroll:Bool, isGhostTapping:Bool, script:ScriptHandler, playStateConfig:PlayStateConfig,
			gameAudio:core.rhythm.audio.GameAudio) {
		this.daSong = daSong;
		this.isDownscroll = isDownscroll;
		this.playStateConfig = playStateConfig;
		this.gameAudio = gameAudio;
		#if HSCRIPT_ALLOWED
		scriptNC = script;
		#end

		loadJson();

		#if HSCRIPT_ALLOWED
		scriptNC.loadFolder('scripts/noteskins/$noteSkin');
		scriptNC.executeAll();
		#end

		var globalOffset = 0;
		for (i in 0...daSong.chars.length) {
			var charData = daSong.chars[i];
			var strumPos = charData.strums?.position;
			var isPlayer = CharacterController.namesPlayer.contains(charData.role);
			var strumsVis = charData?.strums?.visible ?? true;
			var notesVis = charData?.strums?.notesVisible ?? strumsVis;

			var strums = buildStrumline(charData.id, isPlayer, isGhostTapping);
			strums.strumsVisible = strumsVis;
			strums.notesVisible = notesVis;

			// compat maps
			charStrumOffsets.set(charData.id, globalOffset);
			strumsGlobalOffset.set(strums, globalOffset);
			globalOffset += keys;

			var bg = bglaneBackdrop(strumPos != null ? strumPos[0] : 0);
			strums.blackBack = bg;
			blackBacks.add(bg);

			strums.generateStrums(strumPos != null ? strumPos[0] : 0, strumPos != null ? strumPos[1] : 0, daSong, isDownscroll, SaveData.data.middlescroll);
			bg.visible = strumsVis && notesVis;

			for (s in strums.strums.members)
				if (s != null)
					this.strums.add(s);
		}

		confirmAnims = [for (i in 0...keys) 'confirm$i'];
		staticAnims = [for (i in 0...keys) 'static$i'];
		Console.log("Created Strums");
	}

	function buildStrumline(charId:String, isPlayer:Bool, isGhostTapping:Bool):Strumline {
		var skin = charSkin(charId);
		var strums = new Strumline(charId, isPlayer, keys, skin, skinPart(skin, 'strumnotes'), skinPart(skin, 'splashes'), skinPart(skin, 'holdsplashes'),
			noteSkinData.spacing ?? 0, #if HSCRIPT_ALLOWED scriptNC #end
		);
		strums.input.isGhostTapping = isGhostTapping;
		strums.scrollSpeed = scrollSpeed;
		strums.targetScrollSpeed = targetScrollSpeed;
		strums.isDownscroll = isDownscroll;
		strums.noteController = this;
		strumlines.push(strums);
		strumsByChar.set(charId, strums);
		return strums;
	}

	public function getStrumline(charId:String):Null<Strumline> {
		return strumsByChar.get(charId);
	}

	public function addStrumline(charId:String, isPlayer:Bool, x:Float, y:Float, ?isGhostTapping:Bool = false):Strumline {
		var globalOffset = strums.length;
		var strums = buildStrumline(charId, isPlayer, isGhostTapping);
		charStrumOffsets.set(charId, globalOffset);
		strumsGlobalOffset.set(strums, globalOffset);
		strums.generateStrums(x, y, daSong, isDownscroll, isMiddlescroll);
		for (s in strums.strums.members)
			if (s != null)
				this.strums.add(s);
		return strums;
	}

	public function removeStrumline(charId:String):Bool {
		var strums = strumsByChar.get(charId);
		if (strums == null)
			return false;
		for (s in strums.strums.members)
			this.strums.remove(s, true);
		for (n in strums.notes.members)
			notes.remove(n, true);
		for (s in strums.sustains.members)
			sustains.remove(s, true);
		for (s in strums.splashes.members)
			splashes.remove(s, true);
		for (h in strums.holdsplashes.members)
			holdsplashes.remove(h, true);
		if (strums.blackBack != null)
			blackBacks.remove(strums.blackBack, true);
		strumlines.remove(strums);
		strumsByChar.remove(charId);
		charStrumOffsets.remove(charId);
		strumsGlobalOffset.remove(strums);
		strums.destroy();
		return true;
	}

	public function skinPart(skin:String, part:String):Dynamic {
		var key = '$skin|$part';
		if (!_skinParts.exists(key)) {
			var data = NoteSkins.read(skin, part);
			data ??= skin != noteSkin ? skinPart(noteSkin, part) : (skin != NoteSkins.DEFAULT ? NoteSkins.read(NoteSkins.DEFAULT, part) : null);
			_skinParts.set(key, data);
		}
		return _skinParts.get(key);
	}

	public function charSkin(charId:String):String {
		var c = Lambda.find(daSong.chars, c -> c.id == charId);
		var skin:String = c?.strums?.noteSkin;
		return skin != null && skin != '' ? skin : noteSkin;
	}

	public function changeCharSkin(charId:String, skin:String):Bool {
		var charData = Lambda.find(daSong.chars, c -> c.id == charId);
		var strums = strumsByChar.get(charId);
		if (charData == null || strums == null || !NoteSkins.exists(skin))
			return false;
		if (charData.strums == null)
			charData.strums = {};
		charData.strums.noteSkin = skin;
		var data:NoteSkinData = skinPart(skin, 'strumnotes');
		strums.applySkin(skin, data);
		strums.doApplyScrollDirection(isDownscroll);
		strums.doApplyMiddlescroll(isMiddlescroll, daSong);
		var reskin = (n:Note) -> {
			if (n == null || n.wasGoodHit || n.strumline != strums)
				return;
			var lane = n.direction;
			n.direction = lane % keys;
			n.noteSkin = skin;
			@:privateAccess n.noteSkinData = data;
			n.loadSprite(data);
			n.direction = lane;
		};
		for (n in strums.notes.members)
			reskin(n);
		for (n in strums.sustains.members)
			reskin(n);
		for (n in unspawnNotes)
			reskin(n);
		if (game.PlayState.instance?.modchartSystem != null)
			game.PlayState.instance.modchartSystem.syncBase();
		return true;
	}

	public function popupImage(kind:String, key:String):Dynamic {
		var group:Dynamic = popupsData != null ? Reflect.field(popupsData, kind) : null;
		var entry:Dynamic = group != null ? Reflect.field(group, key) : null;
		if (entry?.path == null)
			return null;
		var folder:String = popupsData.folder ?? NoteSkins.imageFolder(noteSkin, 'popups');
		var path = Paths.getPath(folder + entry.path, 'image');
		return path != null ? {path: path, scale: entry.scale ?? 1.0, pixel: entry.pixel == true} : null;
	}

	public function loadJson():Void {
		globalData = core.ConfigMain.globalData;
		var player = daSong != null ? Lambda.find(daSong.chars, c -> CharacterController.namesPlayer.contains(c.role)) : null;
		if (player?.strums?.noteSkin != null && player.strums.noteSkin != '')
			noteSkin = player.strums.noteSkin;
		else if (daSong?.noteSkin != null)
			noteSkin = daSong.noteSkin;
		else if (globalData != null)
			noteSkin = globalData.noteSkin;
		if (!NoteSkins.exists(noteSkin)) {
			Console.log('[NoteController] note skin "$noteSkin" not found, using ${NoteSkins.DEFAULT}', true);
			noteSkin = NoteSkins.DEFAULT;
		}
		noteSkinData = skinPart(noteSkin, 'strumnotes');
		splashesSkinData = skinPart(noteSkin, 'splashes');
		holdSkinData = skinPart(noteSkin, 'holdsplashes');
		popupsData = NoteSkins.read(noteSkin, 'popups');

		var ratingPath = Paths.getPath('data/ratings', 'json');
		ratingData = FormatJson.readJson(ratingPath);
		if (ratingData == null || ratingData.ratings == null) {
			trace("WARNING: ratings.json not found or invalid");
		} else {
			var best = 0.0;
			cachedRatings = [];
			for (rating in ratingData.ratings) {
				if (rating.window != null && rating.window > best)
					best = rating.window;
				if (rating.window != null)
					cachedRatings.push(rating);
				else if (rating.miss == true) {
					cachedMissHealth = rating.health;
					cachedMissScore = rating.score;
				}
			}
			cachedRatings.sort((a, b) -> (a.window < b.window) ? -1 : (a.window > b.window ? 1 : 0));
			worstWindow = best > 0 ? best : 166.0;
		}
		keys = noteSkinData.keys ?? 4;
		scrollSpeed = daSong.speed ?? 1.2;
		targetScrollSpeed = scrollSpeed;
		Console.log("Note Skin JSON loaded");
	}

	public function bglaneBackdrop(x:Float):flixel.FlxSprite {
		var spacing:Float = noteSkinData.spacing ?? 0;
		var w:Float = (keys * 112) + (spacing * (keys - 1)) + 45;
		if (isMiddlescroll)
			x = (FlxG.width / 2) - (w / 2);
		var back = new flixel.FlxSprite(x, 0).makeGraphic(Std.int(w), FlxG.height, flixel.util.FlxColor.BLACK);
		var v:Float = SaveData.data.laneBackdrop;
		back.alpha = (v > 1) ? (v / 100) : v;
		return back;
	}

	public function applyScrollDirection(newDownscroll:Bool):Void {
		if (isDownscroll == newDownscroll)
			return;
		isDownscroll = newDownscroll;
		for (strums in strumlines)
			strums.applyScrollDirection(newDownscroll);
		if (game.PlayState.instance?.controllerHUD != null)
			game.PlayState.instance.controllerHUD.applyDownscroll(newDownscroll);
		for (n in notes.members)
			if (n != null)
				n.noteDownscroll = newDownscroll;
		for (n in sustains.members)
			if (n != null)
				n.noteDownscroll = newDownscroll;
		for (n in unspawnNotes)
			if (n != null) {
				n.noteDownscroll = newDownscroll;
				if ((n is NoteSustain))
					cast(n, NoteSustain).flipY = newDownscroll;
			}
		#if HSCRIPT_ALLOWED
		scriptNC.call("postApplyDownscroll", [newDownscroll]);
		#end
	}

	public function applyMiddlescroll(newMiddlescroll:Bool):Void {
		if (isMiddlescroll == newMiddlescroll)
			return;
		isMiddlescroll = newMiddlescroll;
		for (strums in strumlines)
			strums.applyMiddlescroll(newMiddlescroll, daSong);
		#if HSCRIPT_ALLOWED
		scriptNC.call("postApplyMiddlescroll", [newMiddlescroll]);
		#end
	}

	public function updateLaneBackdropAlpha():Void {
		for (strums in strumlines)
			strums.updateLaneBackdropAlpha();
	}

	public function updateAntialiasingLive(enabled:Bool):Void {
		for (strums in strumlines)
			strums.updateAntialiasing(enabled);
	}

	public function tweenScrollSpeed(target:Float, duration:Float, ?ease:flixel.tweens.FlxEase.EaseFunction):Void {
		scrollTween?.cancel();
		if (duration <= 0 || ease == null) {
			scrollSpeed = targetScrollSpeed = target;
			_syncScrollToAll(target);
			return;
		}
		scrollTween = flixel.tweens.FlxTween.num(scrollSpeed, target, duration, {ease: ease}, v -> {
			scrollSpeed = targetScrollSpeed = v;
			_syncScrollToAll(v);
		});
	}

	inline function _syncScrollToAll(v:Float):Void {
		for (strums in strumlines) {
			strums.scrollSpeed = v;
			strums.targetScrollSpeed = v;
		}
	}

	public function generateNotes(songTime:Float, daSong:SongConfig):Void {
		if (daSong.songData == null) {
			Console.log('songData null, generated 0 notes', true);
			return;
		}
		#if HSCRIPT_ALLOWED
		scriptNC.call("onGenerateNotes", []);
		#end

		_noteSpawnIndex = 0;
		rawNoteIndex = 0;
		unspawnNotes = [];
		noteTypeManager = new NoteTypeManager();
		noteTypeManager.initFromNotes(daSong.songData.notes);

		charMap = new Map();
		for (c in daSong.chars)
			charMap.set(c.id, c);

		rawNotes = daSong.songData.notes.copy();
		rawNotes.sort((a, b) -> Std.int(a.time - b.time));

		if (songTime > 0)
			while (rawNoteIndex < rawNotes.length && rawNotes[rawNoteIndex].time < songTime - 1000)
				rawNoteIndex++;

		#if HSCRIPT_ALLOWED
		scriptNC.call("postGenerateNotes", []);
		#end
	}

	function buildNoteFromRaw(data:NoteData):Void {
		var charData = charMap.get(data.char);
		if (charData == null)
			return;
		var strums = strumsByChar.get(charData.id);
		if (strums == null)
			return;
		var strum = strums.strums.members[data.lane];
		if (strum == null)
			return;

		var skinForChar = charSkin(charData.id);
		var charSkinData:NoteSkinData = skinPart(skinForChar, 'strumnotes');
		var noteTypeSkin = getNoteTypeData(data.type);
		var effectiveSkin = (noteTypeSkin?.visual?.noteSkin != null) ? noteTypeSkin.visual.noteSkin : charSkinData;
		var globalLane = (charStrumOffsets.get(charData.id) ?? 0) + data.lane;
		var scrollM = 0.45 * strums.scrollSpeed;

		var note:Note;
		if (strums.notePool.length > 0) {
			note = strums.notePool.pop();
			note.revive();
			note.reinit(data.time, keys, strum.x, 0, effectiveSkin, skinForChar, data.lane);
		} else {
			note = new Note(data.time, keys, strum.x, 0, effectiveSkin, skinForChar, data.lane, data.type);
		}
		note.ID = globalLane;
		note.direction = globalLane;
		note.localLane = data.lane;
		note.strumTime = data.time;
		note.mustPress = CharacterController.namesPlayer.contains(charData.role);
		note.visible = strums.notesVisible;
		note.strum = strum;
		note.noteControl = this;
		note.noteType = data.type ?? 'normal';
		note.strumline = strums;
		note.scrollMult = scrollM;
		note.noteDownscroll = strums.isDownscroll;

		#if HSCRIPT_ALLOWED
		scriptNC.call("onGenerateNote", [note]);
		noteTypeManager.onNoteGenerate(note);
		#end

		if (data.length > 0) {
			var sustain:NoteSustain;
			if (strums.sustainPool.length > 0) {
				sustain = strums.sustainPool.pop();
				sustain.revive();
				sustain.reinitSustain(data.time, keys, strum.x, 0, charSkinData, skinForChar, data.lane, data.length, data.type, false);
			} else {
				sustain = new NoteSustain(data.time, keys, strum.x, 0, charSkinData, skinForChar, data.lane, data.length, data.type, false);
			}
			sustain.ID = globalLane;
			sustain.direction = globalLane;
			sustain.localLane = data.lane;
			sustain.strumTime = data.time;
			sustain.mustPress = note.mustPress;
			sustain.noteControl = this;
			sustain.strum = strum;
			sustain.noteType = data.type ?? 'normal';
			sustain.flipY = strums.isDownscroll;
			sustain.visible = strums.notesVisible;
			sustain.origin.y = 0;
			sustain.strumline = strums;
			sustain.scrollMult = scrollM;
			sustain.noteDownscroll = strums.isDownscroll;
			#if HSCRIPT_ALLOWED
			scriptNC.call("onGenerateSustain", [sustain]);
			#end
			unspawnNotes.push(sustain);

			var sustainEnd:NoteSustain;
			if (strums.sustainPool.length > 0) {
				sustainEnd = strums.sustainPool.pop();
				sustainEnd.revive();
				sustainEnd.reinitSustain(data.time + data.length, keys, strum.x, 0, charSkinData, skinForChar, data.lane, 0, data.type, true);
			} else {
				sustainEnd = new NoteSustain(data.time + data.length, keys, strum.x, 0, charSkinData, skinForChar, data.lane, 0, data.type, true);
			}
			sustainEnd.ID = globalLane;
			sustainEnd.direction = globalLane;
			sustainEnd.localLane = data.lane;
			sustainEnd.strumTime = data.time;
			sustainEnd.mustPress = note.mustPress;
			sustainEnd.noteControl = this;
			sustainEnd.strum = strum;
			sustainEnd.parentNote = sustain;
			sustainEnd.noteType = data.type ?? 'normal';
			sustainEnd.flipY = strums.isDownscroll;
			sustainEnd.visible = strums.notesVisible;
			sustainEnd.origin.y = 0;
			sustainEnd.strumline = strums;
			sustainEnd.scrollMult = scrollM;
			sustainEnd.noteDownscroll = strums.isDownscroll;
			#if HSCRIPT_ALLOWED
			scriptNC.call("onGenerateEndSustain", [sustainEnd]);
			#end
			unspawnNotes.push(sustainEnd);
		}
		unspawnNotes.push(note);
	}

	public function update(songTime:Float):Void {
		var elapsed = FlxG.elapsed;
		for (strums in strumlines)
			strums.update(elapsed);
		for (strums in strumlines)
			if (strums.isPlayer) {
				scrollSpeed = strums.scrollSpeed;
				break;
			}
		updateNotes(songTime);
	}

	public function updateNotes(songTime:Float):Void {
		#if HSCRIPT_ALLOWED
		scriptNC.call("onNoteUpdate", [songTime]);
		#end

		while (rawNoteIndex < rawNotes.length) {
			var data = rawNotes[rawNoteIndex];
			if (data.time - songTime > GENERATE_AHEAD_MS)
				break;
			buildNoteFromRaw(data);
			rawNoteIndex++;
			rawNotes[rawNoteIndex - 1] = null;
		}

		var spawnWindow:Float = Math.max(2000, (FlxG.height + 200) / (0.45 * Math.max(0.1, Math.min(scrollSpeed, targetScrollSpeed))));
		while (_noteSpawnIndex < unspawnNotes.length) {
			var note = unspawnNotes[_noteSpawnIndex];
			var sustain = Std.downcast(note, NoteSustain);
			var spawnTime = note.strumTime;
			if (sustain != null && sustain.isSustainEnd && sustain.parentNote != null)
				spawnTime = sustain.parentNote.strumTime;

			if (spawnTime - songTime < spawnWindow) {
				var strums = note.strumline;
				note.visible = note.strum.visible && (strums != null ? strums.notesVisible : true);
				if (sustain != null) {
					sustains.add(sustain);
					strums?.sustains.add(sustain);
				} else {
					notes.add(note);
					strums?.notes.add(note);
				}
				_noteSpawnIndex++;
			} else
				break;
		}

		toDestroySet.clear();
		activeOpponentHolds.clear();

		// notes
		for (note in notes.members) {
			if (note == null)
				continue;
			#if HSCRIPT_ALLOWED
			if (scriptNC.hasScripts && scriptNC.callCancellable('onNoteMovementCancel', [note]))
				continue;
			#end
			var downscroll = note.noteDownscroll;
			var sm = note.scrollMult;
			note.x = note.strum.x;
			var timeDiff = note.strumTime - songTime;
			note.y = downscroll ? note.strum.y - (timeDiff * sm) : note.strum.y + (timeDiff * sm);

			#if HSCRIPT_ALLOWED
			if (scriptNC.hasScripts)
				scriptNC.call("onNoteMovement", [note, songTime]);
			#end

			if (note.tooLate && !note.wasMissed && !note.wasGoodHit) {
				note.wasMissed = true;
				note.alpha = 0.4;
				if (charController != null)
					charController.playMissAnim(note.direction);
				note.strumline?.input.onMiss(playStateConfig, this, gameAudio);
			}
			if (!note.mustPress && note.wasGoodHit && !note.alive)
				toDestroySet.set(note, true);

			if (!downscroll && note.y + note.frameHeight * note.scale.y < 0) {
				if (note.mustPress && !note.wasGoodHit && !note.wasMissed) {
					note.wasMissed = true;
					note.alpha = 0.4;
					if (charController != null)
						charController.playMissAnim(note.direction);
					note.strumline?.input.onMiss(playStateConfig, this, gameAudio);
				}
				toDestroySet.set(note, true);
			} else if (downscroll && note.y > FlxG.height) {
				if (note.mustPress && !note.wasGoodHit && !note.wasMissed) {
					note.wasMissed = true;
					note.alpha = 0.4;
					if (charController != null)
						charController.playMissAnim(note.direction);
					note.strumline?.input.onMiss(playStateConfig, this, gameAudio);
				}
				toDestroySet.set(note, true);
			}
		}

		for (sustain in sustains.members) {
			if (sustain == null)
				continue;
			var lane = sustain.direction;
			var strums = sustain.strumline;
			var downscroll = sustain.noteDownscroll;
			var sm = sustain.scrollMult;
			var lk = sustain.localLane;

			// CPU hold splashes
			if (!isMiddlescroll && !sustain.mustPress) {
				var inHold = songTime >= sustain.strumTime && songTime <= (sustain.strumTime + sustain.length);
				if (inHold) {
					if (!sustain.isHeld) {
						sustain.isHeld = true;
						strums?.spawnHoldSplash(sustain.strum, lk, sustain.noteType);
						_syncHoldSplashToGlobal(strums);
					}
					sustain.strum.playAnim('confirm$lk', false);
					if (strums != null) {
						strums.activeOpponentHolds.set(lane, true);
						activeOpponentHolds.set(lane, true);
					}
				} else if (sustain.isHeld) {
					sustain.isHeld = false;
					strums?.stopHoldSplash(sustain.strum);
					sustain.strum.playAnim('static$lk', true);
					if (strums != null) {
						strums.activeOpponentHolds.remove(lane);
						activeOpponentHolds.remove(lane);
					}
				}
			}
			if (sustain.mustPress && SaveData.data.botplay) {
				var inHold = songTime >= sustain.strumTime && songTime <= (sustain.strumTime + sustain.length);
				if (inHold) {
					sustain.wasNoteHit = true;
					if (!sustain.isHeld) {
						sustain.isHeld = true;
						strums?.spawnHoldSplash(sustain.strum, lk, sustain.noteType);
						_syncHoldSplashToGlobal(strums);
					}
					if (strums != null) {
						strums.activeOpponentHolds.set(lane, true);
						activeOpponentHolds.set(lane, true);
					}
					sustain.strum.playAnim(confirmAnims[lk], false);
				} else if (sustain.isHeld) {
					sustain.isHeld = false;
					strums?.stopHoldSplash(sustain.strum);
					sustain.strum.playAnim(staticAnims[lk], true);
					if (strums != null) {
						strums.activeOpponentHolds.remove(lane);
						activeOpponentHolds.remove(lane);
					}
				}
			}

			// sustain end
			if (sustain.isSustainEnd) {
				#if HSCRIPT_ALLOWED
				if (scriptNC.callCancellable('onEndSustainMovementCancel', []))
					continue;
				#end
				var body = sustain.parentNote;
				if (body == null) {
					toDestroySet.set(sustain, true);
					continue;
				}
				if (!body.alive)
					continue;
				if (toDestroySet.exists(body)) {
					toDestroySet.set(sustain, true);
					continue;
				}
				sustain.x = body.x;
				sustain.origin.y = 0;
				var endH = sustain.frameHeight * sustain.scale.y;
				sustain.flipY = downscroll;
				sustain.y = downscroll ? body.y - endH : body.y + (body.frameHeight * body.scale.y);
				var strumMid = sustain.strum.y + (sustain.strum.frameHeight * 0.5) - sustain.strum.offset.y;
				sustain.alpha = downscroll ? (sustain.y >= strumMid ? 0 : 1) : ((sustain.y + endH) <= strumMid ? 0 : 1);
				#if HSCRIPT_ALLOWED
				if (scriptNC.hasScripts)
					scriptNC.call("onEndSustainMovement", [songTime]);
				#end
				continue;
			}

			// sustain body
			#if HSCRIPT_ALLOWED
			if (scriptNC.hasScripts && scriptNC.callCancellable('onSustainMovementCancel', []))
				continue;
			#end
			var scx = sustain.strum.x - sustain.strum.offset.x + sustain.strum.frameWidth * sustain.strum.scale.x * 0.5;
			sustain.x = scx - sustain.frameWidth * sustain.scale.x * 0.5;
			var strumMid = sustain.strum.y + (sustain.strum.frameHeight * 0.5) - (sustain.strum.offset.y * 1.45);
			var scaledH:Float;
			if (sustain.isHeld && sustain.strumTime <= songTime) {
				var rem = Math.max(0, (sustain.strumTime + sustain.length) - songTime);
				scaledH = rem * sm;
				sustain.scale.y = scaledH / sustain.frameHeight;
				sustain.y = downscroll ? (strumMid - scaledH) : strumMid;
			} else {
				scaledH = sustain.length * sm;
				sustain.scale.y = scaledH / sustain.frameHeight;
				var td = sustain.strumTime - songTime;
				var sy = downscroll ? (sustain.strum.y - (td * sm)) : (sustain.strum.y + (td * sm));
				sustain.y = downscroll ? (sy + sustain.strum.frameHeight * 0.5 - scaledH) : (sy + sustain.strum.frameHeight * 0.5);
			}
			sustain.offset.y = 0;
			sustain.clipRect = null;
			#if HSCRIPT_ALLOWED
			if (scriptNC.hasScripts)
				scriptNC.call("onSustainMovement", [sustain, songTime]);
			#end
			if (sustain.strumTime + sustain.length < songTime) {
				if (sustain.isHeld) {
					sustain.isHeld = false;
					strums?.stopHoldSplash(sustain.strum);
				}
				toDestroySet.set(sustain, true);
			} else if (!downscroll && sustain.y + scaledH < 0) {
				toDestroySet.set(sustain, true);
			} else if (downscroll && sustain.y - sustain.offset.y > FlxG.height) {
				toDestroySet.set(sustain, true);
			}
		}

		for (strums in strumlines) {
			for (hs in strums.holdsplashes.members) {
				if (hs == null || !hs.alive)
					continue;
				var strum = strums.holdSplashToStrum.get(hs);
				if (strum != null)
					hs.setPosition(strum.x, strum.y);
			}
		}

		for (note in toDestroySet.keys())
			if (note != null)
				destroyNotes(note);

		#if HSCRIPT_ALLOWED
		scriptNC.call("postNoteUpdate", [songTime]);
		#end
	}

	inline function _syncHoldSplashToGlobal(strums:Strumline):Void {
		if (strums == null)
			return;
		for (h in strums.holdsplashes.members)
			if (h != null && !holdsplashes.members.contains(h))
				holdsplashes.add(h);
	}

	public function spawnSplash(strum:StrumNote, direction:Int, noteType:String = 'normal'):Void {
		for (strums in strumlines) {
			if (strums.strums.members.indexOf(strum) >= 0) {
				strums.spawnSplash(strum, direction, noteType);
				for (s in strums.splashes.members)
					if (s != null && !splashes.members.contains(s))
						splashes.add(s);
				return;
			}
		}
	}

	public function recycleSplash(splash:NoteSplash):Void {
		var strums = splash.strumline;
		if (strums != null)
			strums.recycleSplash(splash);
		splashes.remove(splash, true);
	}

	public function spawnHoldSplash(strum:StrumNote, direction:Int, noteType:String = 'normal'):Void {
		for (strums in strumlines) {
			if (strums.strums.members.indexOf(strum) >= 0) {
				strums.spawnHoldSplash(strum, direction, noteType);
				_syncHoldSplashToGlobal(strums);
				return;
			}
		}
	}

	public function stopHoldSplash(strum:StrumNote):Void {
		for (strums in strumlines)
			if (strums.strums.members.indexOf(strum) >= 0) {
				strums.stopHoldSplash(strum);
				return;
			}
	}

	public function recycleHoldSplash(hs:HoldSplash):Void {
		for (strums in strumlines) {
			if (strums.holdSplashToStrum.exists(hs)) {
				strums.recycleHoldSplash(hs);
				holdsplashes.remove(hs, true);
				return;
			}
		}
	}

	public function destroyNotes(note:Note):Void {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onDestroyNotesCancel', []))
			return;
		#end
		note.strumline?.destroyNote(note);
		if ((note is NoteSustain))
			sustains.remove(cast note, true);
		else
			notes.remove(note, true);
		#if HSCRIPT_ALLOWED
		scriptNC.call("onDestroyNotes", [note]);
		#end
	}

	public function getHittableNote(charId:String, dir:Int, mustPress:Bool = true):Note {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onHittableNoteCancel', []))
			return null;
		#end
		var strums = strumsByChar.get(charId);
		return strums?.getHittableNote(dir, mustPress);
	}

	public function getHealthDrain(note:Note):Float {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onHealthDrainCancel', []))
			return 0.0;
		#end
		return cachedMissHealth;
	}

	public function getMissScore():Int {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onMissScoreCancel', []))
			return 0;
		#end
		return cachedMissScore;
	}

	public function getRatingForDiff(diff:Float):Null<Dynamic> {
		if (cachedRatings.length == 0)
			return null;
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onRatingDiffCancel', []))
			return null;
		#end
		var absDiff = Math.abs(diff);
		for (r in cachedRatings)
			if (absDiff <= r.window)
				return r;
		return null;
	}

	public function getCharStrums(charId:String):Array<StrumNote> {
		#if HSCRIPT_ALLOWED
		if (scriptNC.callCancellable('onGetCharStrumsCancel', []))
			return [];
		#end
		var strums = strumsByChar.get(charId);
		if (strums == null)
			return [];
		#if HSCRIPT_ALLOWED
		scriptNC.call("onGetCharStrums", []);
		#end
		var result = [for (s in strums.strums.members) if (s != null) s];
		#if HSCRIPT_ALLOWED
		scriptNC.call("postGetCharStrums", []);
		#end
		return result;
	}

	function getNoteTypeData(noteType:String):Null<core.json.objects.NoteTypeData> {
		if (noteType == null || noteType == 'normal' || noteType == '')
			return null;
		if (_noteTypeCache.exists(noteType))
			return _noteTypeCache.get(noteType);
		var path = Paths.getPath('data/notetypes/$noteType', 'json');
		var data:core.json.objects.NoteTypeData = path != null ? FormatJson.readJson(path) : null;
		_noteTypeCache.set(noteType, data);
		return data;
	}

	public function destroy():Void {
		rawNotes = null;
		charMap = null;
		cachedRatings = null;
		_noteTypeCache = null;
		for (strums in strumlines)
			strums.destroy();
		strumlines = null;
		strumsByChar = null;
		strumsGlobalOffset = null;
		charStrumOffsets = null;
		activeOpponentHolds = null;
		strums.destroy();
		strums = null;
		notes.destroy();
		notes = null;
		sustains.destroy();
		sustains = null;
		splashes.destroy();
		splashes = null;
		holdsplashes.destroy();
		holdsplashes = null;
		blackBacks.destroy();
		blackBacks = null;
		scrollTween?.cancel();
	}
}

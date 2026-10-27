package game.objects.sprites.notes;

import core.json.objects.NoteSkinData;
import core.json.song.SongData.SongConfig;
import flixel.group.FlxGroup.FlxTypedGroup;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

/*
	The Strumline class serves as a collection of strums, 
	notes, splashes, and sustains, organized by character.
 */
class Strumline {
	public var charId:String;
	public var isPlayer:Bool;

	public var blackBack:flixel.FlxSprite;
	public var strums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	public var sustains:FlxTypedGroup<NoteSustain> = new FlxTypedGroup<NoteSustain>();
	public var splashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();
	public var holdsplashes:FlxTypedGroup<HoldSplash> = new FlxTypedGroup<HoldSplash>();

	public var keys:Int = 4;
	public var spacing:Float = 0;
	public var noteSkin:String;
	public var noteSkinData:NoteSkinData;
	public var splashesSkinData:NoteSkinData;
	public var holdSkinData:NoteSkinData;

	public var scrollSpeed:Float = 1.0;
	public var targetScrollSpeed:Float = 1.0;
	public var lerpSpeed:Float = 5.0;

	public var isDownscroll:Bool = false;
	public var isMiddlescroll:Bool = false;
	public var strumsVisible:Bool = true;
	public var notesVisible:Bool = true;

	public var activeOpponentHolds:Map<Int, Bool> = new Map();

	// pools yep
	final POOL_LENGTH:Int = 48;

	public var notePool:Array<Note> = [];
	public var sustainPool:Array<NoteSustain> = [];
	public var splashPool:Array<NoteSplash> = [];
	public var holdsplashPool:Array<HoldSplash> = [];
	public var holdSplashToStrum:Map<HoldSplash, StrumNote> = new Map();

	public var baseX:Array<Float> = [];
	public var baseY:Array<Float> = [];

	public var input:game.controllers.InputController;

	@:allow(game.controllers.NoteController)
	var noteController:game.controllers.NoteController;

	#if HSCRIPT_ALLOWED
	var script:ScriptHandler;
	#end

	public function new(charId:String, isPlayer:Bool, keys:Int, noteSkin:String, noteSkinData:NoteSkinData, splashesSkinData:NoteSkinData,
			holdSkinData:NoteSkinData, spacing:Float, #if HSCRIPT_ALLOWED script:ScriptHandler #end) {
		this.charId = charId;
		this.isPlayer = isPlayer;
		this.keys = keys;
		this.noteSkin = noteSkin;
		this.noteSkinData = noteSkinData;
		this.splashesSkinData = splashesSkinData;
		this.holdSkinData = holdSkinData;
		this.spacing = spacing;
		this.input = new game.controllers.InputController();
		#if HSCRIPT_ALLOWED
		this.script = script;
		#end
	}

	public function generateStrums(x:Float, y:Float, song:SongConfig, isDownscroll:Bool, isMiddlescroll:Bool):Void {
		this.isDownscroll = isDownscroll;
		this.isMiddlescroll = isMiddlescroll;

		var charBaseY:Float = game.PlayStateConfig.strumLineY + y;

		for (i in 0...keys) {
			#if HSCRIPT_ALLOWED
			script.call("onBuildStrums", []);
			#end

			var bx:Float = x + i * (112 + spacing);
			var strum = new StrumNote(bx, charBaseY, noteSkinData.props, noteSkin);
			strum.laneIndex = i;
			strum.playAnim('static$i');
			strum.applyShader(noteSkinData);
			strum.visible = strumsVisible;

			baseX.push(bx);
			baseY.push(charBaseY);

			if (!game.PlayStateConfig.isStoryMode && !game.PlayState.instance.isRewind) {
				strum.alpha = 0;
				flixel.tweens.FlxTween.tween(strum, {alpha: 1}, 0.5, {startDelay: 0.5 + (0.2 * i)});
			}

			strums.add(strum);

			#if HSCRIPT_ALLOWED
			script.call("safeBuildStrums", []);
			script.call("postBuildStrums", []);
			#end
		}

		doApplyScrollDirection(isDownscroll);
		doApplyMiddlescroll(isMiddlescroll);
	}

	public function applyScrollDirection(newDownscroll:Bool):Void {
		if (isDownscroll == newDownscroll)
			return;
		isDownscroll = newDownscroll;
		doApplyScrollDirection(newDownscroll);
	}

	public function doApplyScrollDirection(newDownscroll:Bool):Void {
		for (i in 0...strums.members.length) {
			var strum = strums.members[i];
			if (strum == null)
				continue;
			strum.y = baseY[i] + (newDownscroll ? 500 : 0);
		}
		if (noteController != null) {
			for (s in noteController.unspawnNotes) {
				if (s == null || s.strum == null)
					continue;
				if (strums.members.indexOf(s.strum) < 0)
					continue;
				if ((s is NoteSustain))
					cast(s, NoteSustain).flipY = newDownscroll;
			}
		}
		for (s in sustains.members)
			if (s != null)
				s.flipY = newDownscroll;
	}

	public function applyMiddlescroll(newMiddlescroll:Bool, song:SongConfig):Void {
		if (isMiddlescroll == newMiddlescroll)
			return;
		isMiddlescroll = newMiddlescroll;
		doApplyMiddlescroll(newMiddlescroll, song);
	}

	public function doApplyMiddlescroll(newMiddlescroll:Bool, ?song:SongConfig):Void {
		var centerX:Float = (flixel.FlxG.width - ((keys * 112) + ((keys - 1) * spacing))) / 2 - 25;
		for (i in 0...strums.members.length) {
			var strum = strums.members[i];
			if (strum == null)
				continue;
			if (newMiddlescroll) {
				if (isPlayer) {
					strum.x = centerX + i * (112 + spacing);
					strum.visible = true;
					if (blackBack != null) {
						var w:Float = (keys * 112) + ((keys - 1) * spacing) + 45;
						blackBack.x = (flixel.FlxG.width / 2) - (w / 2);
						blackBack.visible = strumsVisible && notesVisible;
					}
				} else {
					strum.visible = false;
					if (blackBack != null)
						blackBack.visible = false;
				}
			} else {
				strum.x = baseX[i];
				if (song != null) {
					var charData = Lambda.find(song.chars, c -> c.id == charId);
					strum.visible = charData?.strums?.visible ?? true;
				}
				if (blackBack != null) {
					if (baseX.length > 0)
						blackBack.x = baseX[0];
					blackBack.visible = strumsVisible && notesVisible;
				}
			}
		}
		var notesBeVisible:Bool = newMiddlescroll && isPlayer;
		for (strumline in [notes, sustains, holdsplashes]) {
			if (strumline != null)
				strumline.visible = notesBeVisible;
		}
	}

	public function spawnSplash(strum:StrumNote, direction:Int, noteType:String = 'normal'):Void {
		if (splashesSkinData == null)
			return;
		var splash:NoteSplash;
		if (splashPool.length > 0) {
			splash = splashPool.pop();
			splash.revive();
			splash.reinitSplash(strum.x, strum.y, splashesSkinData, noteSkin, direction % keys, noteType);
		} else {
			splash = new NoteSplash(keys, strum.x, strum.y, splashesSkinData, noteSkin, direction % keys, noteType);
		}
		splashes.add(splash);
		splash.playAnim('note$direction', true);
	}

	public function recycleSplash(splash:NoteSplash):Void {
		splashes.remove(splash, true);
		splash.kill();
		if (splashPool.length < POOL_LENGTH)
			splashPool.push(splash);
		else
			splash.destroy();
	}

	public function spawnHoldSplash(strum:StrumNote, direction:Int, noteType:String = 'normal'):Void {
		if (holdSkinData == null)
			return;
		if (Lambda.exists(holdSplashToStrum, v -> v == strum))
			return;
		var hs:HoldSplash;
		if (holdsplashPool.length > 0) {
			hs = holdsplashPool.pop();
			hs.revive();
			hs.reinitHoldSplash(strum.x, strum.y, holdSkinData, noteSkin, direction % keys, noteType);
		} else {
			hs = new HoldSplash(keys, strum.x, strum.y, holdSkinData, noteSkin, direction % keys, noteType);
		}
		holdsplashes.add(hs);
		holdSplashToStrum.set(hs, strum);
	}

	public function stopHoldSplash(strum:StrumNote):Void {
		for (hs in holdsplashes.members) {
			if (hs == null || holdSplashToStrum.get(hs) != strum)
				continue;
			holdSplashToStrum.remove(hs);
			holdsplashes.remove(hs, true);
			hs.animation.finishCallback = function(name:String) {
				hs.animation.finishCallback = null;
				hs.kill();
				if (holdsplashPool.length < POOL_LENGTH)
					holdsplashPool.push(hs);
				else
					hs.destroy();
			};
			hs.endHold();
			break;
		}
	}

	public function recycleHoldSplash(hs:HoldSplash):Void {
		holdSplashToStrum.remove(hs);
		holdsplashes.remove(hs, true);
		hs.kill();
		if (holdsplashPool.length < POOL_LENGTH)
			holdsplashPool.push(hs);
		else
			hs.destroy();
	}

	public function destroyNote(note:Note):Void {
		if ((note is NoteSustain)) {
			sustains.remove(cast note, true);
			note.kill();
			if (sustainPool.length < POOL_LENGTH)
				sustainPool.push(cast note);
			else
				note.destroy();
		} else {
			notes.remove(note, true);
			note.kill();
			if (notePool.length < POOL_LENGTH)
				notePool.push(note);
			else
				note.destroy();
		}
	}

	public function getHittableNote(dir:Int, mustPress:Bool = true):Note {
		for (note in notes.members) {
			if (note == null || !note.alive || note.mustPress != mustPress)
				continue;
			if (note.direction % keys != dir)
				continue;
			var isHittable = mustPress ? (note.canBeHit && !note.wasGoodHit) : note.wasGoodHit;
			if (isHittable)
				return note;
		}
		return null;
	}

	public function updateAntialiasing(enabled:Bool):Void {
		var groups:Array<Dynamic> = [strums, notes, sustains, splashes, holdsplashes];
		for (group in groups)
			for (item in (group : FlxTypedGroup<Dynamic>).members)
				if (item != null)
					item.antialiasing = enabled;
		if (blackBack != null)
			blackBack.antialiasing = enabled;
	}

	public function updateLaneBackdropAlpha():Void {
		if (blackBack == null)
			return;
		var v:Float = SaveData.data.laneBackdrop;
		blackBack.alpha = (v > 1) ? (v / 100) : v;
	}

	public function applySkin(newSkin:String, newSkinData:NoteSkinData):Void {
		noteSkin = newSkin;
		noteSkinData = newSkinData;
		for (strum in strums.members) {
			if (strum == null)
				continue;
			var ka = strum.alpha;
			var kv = strum.visible;
			strum.noteSkin = newSkin;
			strum.loadSprite(strum.x, strum.y, newSkinData.props);
			strum.playAnim('static${strum.laneIndex}', true);
			strum.applyShader(newSkinData);
			strum.alpha = ka;
			strum.visible = kv;
		}
	}

	public function update(elapsed:Float):Void {
		scrollSpeed = flixel.math.FlxMath.lerp(scrollSpeed, targetScrollSpeed, elapsed * lerpSpeed);
	}

	public function destroy():Void {
		for (n in notePool)
			n.destroy();
		for (n in sustainPool)
			n.destroy();
		for (n in splashPool)
			n.destroy();
		for (n in holdsplashPool)
			n.destroy();
		notePool = null;
		sustainPool = null;
		splashPool = null;
		holdsplashPool = null;
		holdSplashToStrum = null;
		activeOpponentHolds = null;
		strums.destroy();
		notes.destroy();
		sustains.destroy();
		splashes.destroy();
		holdsplashes.destroy();
		strums = null;
		notes = null;
		sustains = null;
		splashes = null;
		holdsplashes = null;
		if (blackBack != null) {
			blackBack.destroy();
			blackBack = null;
		}
	}
}

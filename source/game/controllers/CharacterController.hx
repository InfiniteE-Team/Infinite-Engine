package game.controllers;

import game.PlayState;
import game.PlayStateConfig;
import game.objects.sprites.Character;
import core.assets.FunkinSprite;
import core.assets.FunkinObjectRegistry;
import game.controllers.NoteController;
import core.config.Controls;
import game.objects.sprites.notes.Note;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.rhythm.audio.GameAudio;
#if HSCRIPT_ALLOWED
import core.scripting.ScriptHandler;
#end

class CharacterController extends FunkinObjectRegistry {
	public var isPlayer:Bool = true;

	public var chars:Character;

	var control:Controls;

	public static var namesPlayer:Array<String> = ['bf', 'boyfriend', 'player'];
	public static var namesGf:Array<String> = ['gf', 'girlfriend', 'mid', 'idk'];
	public static var namesOpponent:Array<String> = ['opponent', 'dad', 'bot', 'cpu'];

	var playerChars:Array<Character> = [];
	var opponentChars:Array<Character> = [];
	var gfChars:Array<Character> = [];

	var input:InputController = new InputController();

	#if HSCRIPT_ALLOWED
	var scriptMap:Map<String, ScriptHandler> = [];
	#end

	public function new(?id:String, ?x:Float = 0, ?y:Float = 0) {
		super(id, x, y);
		control = core.ConfigMain.controls;
	}

	public function loadCharacter(id:String, name:String, role:String, targetGroup:FlxTypedGroup<flixel.FlxBasic>, script:ScriptHandler):Character {
		if (existsId(id)) {
			return cast(get(id), Character);
		}
		chars = new Character(id, name);

		#if HSCRIPT_ALLOWED
		scriptMap.set(id, script);
		#end

		registry.set(id, chars);
		for (layer in chars.layers)
			targetGroup.add(layer);
		targetGroup.add(chars);

		var namesIdk = namesPlayer.contains(role) ? playerChars : namesOpponent.contains(role) ? opponentChars : namesGf.contains(role) ? gfChars : null;
		if (namesIdk != null)
			namesIdk.push(chars);

		return chars;
	}

	public function processInput(noteController:NoteController, gameAudio:GameAudio, playStateConfig:PlayStateConfig) {
		input.isGhostTapping = core.config.SaveData.data.ghosttaping;
		for (char in playerChars) {
			var strums = noteController.getCharStrums(char.id);
			for (i in 0...strums.length)
				updatePlayerLane(char, strums, i, noteController, gameAudio, playStateConfig);
		}
		for (char in opponentChars) {
			var strums = noteController.getCharStrums(char.id);
			#if HSCRIPT_ALLOWED
			var charScript = scriptMap.get(char.id);
			#end
			for (i in 0...strums.length) {
				var note = noteController.getHittableNote(char.id, i, false);
				if (note != null) {
					input.isCPUHit(strums, noteController, char.id, i);
					#if HSCRIPT_ALLOWED
					if (charScript != null)
						charScript.call("onNoteHitCPU", []);
					#end
				} else {
					#if HSCRIPT_ALLOWED
					if (charScript != null)
						charScript.call("onNoteSustainCPU", []);
					#end
					var songPos = core.rhythm.RhythmCore.songPosition;
					var holdingActive = false;
					for (sustain in noteController.sustains.members) {
						if (sustain == null || !sustain.alive || sustain.strum != strums[i])
							continue;
						if (sustain.mustPress == false && songPos >= sustain.strumTime && songPos <= sustain.strumTime + sustain.length) {
							sustain.isHeld = true;
							strums[i].playAnim('confirm' + i, false);
							holdingActive = true;
							break;
						}
					}
					#if HSCRIPT_ALLOWED
					if (charScript != null)
						charScript.call("postNoteSustainCPU", []);
					#end
					if (!holdingActive)
						strums[i].playAnim('static' + i, true);
				}
			}
		}
	}

	public function isSinging(noteController:NoteController) {
		var songPos = core.rhythm.RhythmCore.songPosition;
		for (char in opponentChars) {
			var strums = noteController.getCharStrums(char.id);
			for (i in 0...strums.length) {
				var note = noteController.getHittableNote(char.id, i, false);
				if (note != null) {
					setSing(char, note.direction);
					continue;
				}

				var holdingActive = false;
				for (sustain in noteController.sustains.members) {
					if (sustain == null || !sustain.alive || sustain.mustPress || sustain.strum != strums[i])
						continue;
					if (songPos >= sustain.strumTime && songPos <= sustain.strumTime + sustain.length) {
						setSing(char, sustain.direction);
						holdingActive = true;
						break;
					}
				}

				if (!holdingActive)
					strums[i].playAnim('static' + i, true);
			}
		}
	}

	function updatePlayerLane(char:Character, strums, i:Int, nc:NoteController, audio:GameAudio, cfg:PlayStateConfig) {
		var hitNote = input.isPlayerHit(strums, char.id, nc, audio, cfg, i);

		#if HSCRIPT_ALLOWED
		var charScript = scriptMap.get(char.id);
		if (charScript != null) {
			if (hitNote != null)
				charScript.call("onNoteHitPlayer", []);
		}
		#end

		if (input.control.getGroupInput("noteKeys")[i]) {
			if (hitNote != null) {
				setSing(char, hitNote.direction);
				char.isMiss = false;
			} else if (input.control.justPressed("noteKeys", i) && !input.isGhostTapping) {
				char.playAnim('${Character.getCharAnim(i)}-miss', true);
				char.isMiss = true;
			}
		} else {
			getCharMiss(char, nc, strums, i);
		}

		var songPos = core.rhythm.RhythmCore.songPosition;
		for (sustain in nc.sustains.members) {
			if (sustain == null || !sustain.alive || !sustain.mustPress || sustain.strum != strums[i])
				continue;
			if (songPos < sustain.strumTime || songPos > sustain.strumTime + sustain.length)
				continue;
			if (input.control.getGroupInput("noteKeys")[i])
				setSing(char, sustain.direction);
			else
				getCharMiss(char, nc, strums, i);
		}

		#if HSCRIPT_ALLOWED
		if (charScript != null)
			charScript.call("postNoteHitPlayer", []);
		#end
	}

	public function getCharMiss(char:Character, noteController:NoteController, strums, i:Int):Void {
		char.isSing = false;
		char.isMiss = false;
		for (note in noteController.notes.members) {
			if (note == null || !note.alive || !note.mustPress || note.strum != strums[i] || !note.tooLate)
				continue;
			char.playAnim('${Character.getCharAnim(note.direction)}-miss', true);
			char.isMiss = true;
			#if HSCRIPT_ALLOWED
			var charScript = scriptMap.get(char.id);
			if (charScript != null)
				charScript.call("onNoteHitMiss", []);
			#end
		}
	}

	public function danceAll():Void {
		for (chars in [playerChars, opponentChars, gfChars]) {
			for (char in chars)
				char.dance();
		}
	}

	public function removeChar(id:String):Void {
		if (!existsId(id))
			return;

		chars = cast(get(id), Character);
		for (layer in chars.layers) {
			PlayState.instance.remove(layer);
			layer.destroy();
		}
		PlayState.instance.remove(chars);
		chars.destroy();
		registry.remove(id);

		playerChars.remove(chars);
		opponentChars.remove(chars);
		gfChars.remove(chars);

		#if HSCRIPT_ALLOWED
		scriptMap.remove(id);
		#end
	}

	// utils

	inline function setSing(char:Character, dir:Int) {
		#if HSCRIPT_ALLOWED
		var charScript = scriptMap.get(char.id);
		if (charScript != null)
			charScript.call("onSing", []);
		#end

		char.playAnim(Character.getCharAnim(dir), true);
		char.singCountTime = 0;
		char.isSing = true;

		#if HSCRIPT_ALLOWED
		if (charScript != null)
			charScript.call("postSing", []);
		#end
	}

	public function isPlayerMissing():Bool
		return Lambda.exists(playerChars, c -> c.isMiss);

	public function getActiveSingingChar():Null<Character>
		return Lambda.find(playerChars, c -> c.isSing) ?? Lambda.find(opponentChars, c -> c.isSing);

	//

	override public function destroy():Void {
		playerChars = null;
		opponentChars = null;
		gfChars = null;
		#if HSCRIPT_ALLOWED
		scriptMap = null;
		#end
		super.destroy();
	}
}

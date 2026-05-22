package game.controllers;

import game.PlayState;
import game.objects.sprites.Character;
import core.assets.FunkinSprite;
import core.assets.FunkinObjectRegistry;
import game.controllers.NoteController;
import core.config.Controls;
import game.objects.sprites.notes.Note;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.rhythm.audio.GameAudio;

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

	public function new(?id:String, ?x:Float = 0, ?y:Float = 0) {
		super(id, x, y);
		control = Main.controls;
	}

	public function loadCharacter(id:String, name:String, role:String, targetGroup:FlxTypedGroup<flixel.FlxBasic>):FunkinSprite {
		if (existsId(id)) {
			return get(id);
		}
		chars = new Character(id, name);
		registry.set(id, chars);
		for (layer in chars.layers)
			targetGroup.add(layer);
		targetGroup.add(chars);

		if (namesPlayer.contains(role))
			playerChars.push(chars);
		else if (namesOpponent.contains(role))
			opponentChars.push(chars);
		else if (namesGf.contains(role))
			gfChars.push(chars);

		return chars;
	}

	public function isSinging(noteController:NoteController,gameAudio:GameAudio) {
		for (char in playerChars) {
			var charStrums = noteController.getCharStrums(char.id);
			for (i in 0...control.noteKeys.length) {
				var note = input.handleInput(i, noteController, char.id);

				if (input.isPressed(i)) {
					if (note != null) {
						char.playAnim(Character.getCharAnim(note.direction), true);
						char.singCountTime = 0;
						char.isSing = true;
						char.isMiss = false;
						charStrums[i].playAnim('confirm'+i, true);
					} else if (input.justPressed(i)) {
						charStrums[i].playAnim('press'+i, true);
						char.playAnim('${Character.getCharAnim(i)}-miss', true);
						char.isMiss = true;
						gameAudio.onMiss();
						/*
							if (!input.isGhostTapping) {
						}*/
					}
				} else {
					// miss Note detection yep
					char.isSing = false;
					char.isMiss = false;
					for (note in noteController.notes.members) {
						if (note == null || !note.alive || !note.mustPress)
							continue;
						if (note.strum == charStrums[i] && note.tooLate) {
							note.alpha = 0.3;
							char.playAnim('${Character.getCharAnim(note.direction)}-miss', true);
							char.isMiss = true;
							gameAudio.onMiss();
						}
					}
					charStrums[i].playAnim('static'+i, true);
				}
			}
		}

		for (char in opponentChars) {
			var charStrums = noteController.getCharStrums(char.id);

			for (i in 0...charStrums.length) {
				var note = noteController.getHittableNote(char.id, i, false);

				if (note != null) {
					charStrums[i].playAnim('confirm'+i, true);
					note.wasGoodHit = true;
					note.kill();
					char.playAnim(Character.getCharAnim(note.direction), true);
					char.singCountTime = 0;
					char.isSing = true;
				} else
					charStrums[i].playAnim('static'+i, true);
			}
		}
	}

	public function danceAll():Void {
		for (c in playerChars)
			c.dance();
		for (c in opponentChars)
			c.dance();
		for (c in gfChars)
			c.dance();
	}

	public function isPlayerMissing():Bool {
		for (char in playerChars)
			if (char.isMiss)
				return true;
		return false;
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
	}

	public function getActiveSingingChar():Null<Character> {
		for (c in playerChars)
			if (c.isSing)
				return c;
		for (c in opponentChars)
			if (c.isSing)
				return c;
		if (opponentChars.length > 0)
			return opponentChars[0];
		if (playerChars.length > 0)
			return playerChars[0];
		return null;
	}

	override public function destroy():Void {
		playerChars = null;
		opponentChars = null;
		gfChars = null;
		super.destroy();
	}
}

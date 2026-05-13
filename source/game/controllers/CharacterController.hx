package game.controllers;

import game.PlayState;
import game.objects.sprites.Character;
import core.assets.FunkinSprite;
import core.assets.FunkinObjectRegistry;
import core.config.Controls;

class CharacterController extends FunkinObjectRegistry {
	public var isPlayer:Bool = true;

	var chars:Character;
	var control:Controls;

	public var namesPlayer:Array<String> = ['bf', 'boyfriend', 'player'];
	public var namesGf:Array<String> = ['gf', 'girlfriend', 'mid', 'idk'];
	public var namesOpponent:Array<String> = ['opponent', 'dad', 'bot', 'cpu'];

	var playerChars:Array<Character> = [];
	var opponentChars:Array<Character> = [];

	public function new(id:String, ?x:Float = 0, ?y:Float = 0) {
		super(id, x, y);
		control = Main.controls;
	}

	public function loadCharacter(id:String, name:String, role:String):FunkinSprite {
		if (existsId(id)) {
			return get(id);
		}
		chars = new Character(id, name);
		registry.set(id, chars);
		for (layer in chars.layers)
			PlayState.instance.add(layer);
		PlayState.instance.add(chars);

		if (namesPlayer.contains(role))
			playerChars.push(chars);
		else if (namesOpponent.contains(role))
			opponentChars.push(chars);

		return chars;
	}

	public function isSinging(note:NoteController, ?direction:Int) {
		for (char in playerChars) {
			for (i in 0...control.noteKeys.length) {
				if (i >= char.notesAnim.length)
					continue;
				if (control.getInputNotes()[i]) {
					char.playAnim('sing${char.notesAnim[i]}', true);
					char.singCountTime = 0;
					char.isSing = true;
				} else if (note.isMiss && !note.isGood) { // miss
					char.playAnim('sing${char.notesAnim[i]}-miss', true);
					char.isMiss = true;
				}
			}
		}

		for (char in opponentChars) {/*
			if (noteIndex >= char.notesAnim.length)
				return;*/
			//char.playAnim('sing${char.notesAnim[i]}', true);
			char.singCountTime = 0;
			char.isSing = true;
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
	}

	override public function destroy():Void {
		playerChars = null;
		opponentChars = null;
		super.destroy();
	}
}

package game.controllers;

import game.PlayState;
import game.objects.sprites.Character;
import core.assets.FunkinSprite;
import core.assets.FunkinObjectRegistry;
import game.controllers.NoteController;
import core.config.Controls;
import game.objects.sprites.notes.Note;

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

	public function isSinging(noteController:NoteController, ?dir:Int) {
		for (char in playerChars) {
			var charStrums = noteController.getCharStrums(char.id);
			for (i in 0...control.noteKeys.length) {
				if (i >= char.notesAnim.length)
					continue;

				var note = noteController.getHittableNote(char.id, i);

				if (control.getInputNotes()[i]) {
					charStrums[i].playAnim('confirm',true);
					if (note != null) {
						note.wasGoodHit = true;
						note.kill();
						char.playAnim('sing${char.notesAnim[i]}', true);
						char.singCountTime = 0;
						char.isSing = true;
					}
				} else if (note != null && note.tooLate && !note.wasGoodHit) { // miss
					charStrums[i].playAnim('pressed', true);
					char.playAnim('sing${char.notesAnim[i]}-miss', true);
					char.isMiss = true;
				}
				else
					charStrums[i].playAnim('static', true);
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

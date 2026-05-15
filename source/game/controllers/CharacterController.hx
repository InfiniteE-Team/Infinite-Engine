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

	public static var namesPlayer:Array<String> = ['bf', 'boyfriend', 'player'];
	public static var namesGf:Array<String> = ['gf', 'girlfriend', 'mid', 'idk'];
	public static var namesOpponent:Array<String> = ['opponent', 'dad', 'bot', 'cpu'];

	var playerChars:Array<Character> = [];
	var opponentChars:Array<Character> = [];

	var input:InputController = new InputController();

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

				var note = input.handleInput(i, noteController, char.id);

				if (input.isPressed(i)) {
					if (note != null) {
						char.playAnim('sing${char.notesAnim[i]}', true);
						char.singCountTime = 0;
						char.isSing = true;
						char.isMiss = false;
						charStrums[i].playAnim('confirm', true);
					} else if (input.justPressed(i)) {
						charStrums[i].playAnim('pressed', true);
						char.playAnim('sing${char.notesAnim[i]}-miss', true);
						char.isMiss = true;
					} else if (charStrums[i].isFinished('confirm')) {
						charStrums[i].playAnim('pressed', true);
						char.isSing = false;
						char.isMiss = false;
					}
				} else {
					// miss Note detection yep
					for (note in noteController.notes.members) {
						if (note == null || !note.alive || !note.mustPress)
							continue;
						if (note.strum == charStrums[i] && note.tooLate) {
							note.alpha = 0.3;
							char.playAnim('sing${char.notesAnim[i]}-miss', true);
							char.isMiss = true;
						}
					}
					charStrums[i].playAnim('static', true);
					char.isSing = false;
					char.isMiss = false;
				}
			}
		}

		for (char in opponentChars) {
			var charStrums = noteController.getCharStrums(char.id);

			for (i in 0...charStrums.length) {
				var note = noteController.getHittableNote(char.id, i, false);

				if (note != null) {
					charStrums[i].playAnim('confirm', true);
					note.wasGoodHit = true;
					note.kill();
					char.playAnim('sing${char.notesAnim[i]}', true);
					char.singCountTime = 0;
					char.isSing = true;
				} else
					charStrums[i].playAnim('static', true);
			}
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

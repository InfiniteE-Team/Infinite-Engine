package game.controllers;
import game.objects.sprites.notes.Note;
import core.config.Controls;

class InputController {
	public var isGood:Bool = false;

	public static inline var SICK_WINDOW:Float = 45.0;
	public static inline var GOOD_WINDOW:Float = 90.0;
	public static inline var BAD_WINDOW:Float = 135.0;
	public static inline var SHIT_WINDOW:Float = 166.0;

	var control:Controls;

	public function new() {
		control = Main.controls;
	}

	public function handleInput(i:Int, noteController:NoteController, charId:String):Note {
		if (!control.getInputNotes()[i])
			return null;

		var note = noteController.getHittableNote(charId, i);
		if (note != null) {
			if (isPressed(i)){
				note.wasGoodHit = true;
				note.kill();
			}
			else if (justPressed(i))
			{
				note.alpha = note.alpha - 0.3;
			}
		}
		return note;
	}

	public function justPressed(i:Int):Bool
		return control.justPressedNote(i);

	public function isPressed(i:Int):Bool
		return control.getInputNotes()[i];
}

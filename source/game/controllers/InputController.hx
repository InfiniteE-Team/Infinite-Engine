package game.controllers;

import game.objects.sprites.notes.Note;
import game.controllers.NoteController;
import core.rhythm.audio.GameAudio;
import core.config.Controls;

class InputController {
	public var isGood:Bool = false;

	public static inline var SICK_WINDOW:Float = 45.0;
	public static inline var GOOD_WINDOW:Float = 90.0;
	public static inline var BAD_WINDOW:Float = 135.0;
	public static inline var SHIT_WINDOW:Float = 166.0;

	// === HEALTH VALUES ===
	public static inline var SICK_HEALTH:Float = 0.1;
	public static inline var GOOD_HEALTH:Float = 0.05;
	public static inline var BAD_HEALTH:Float = -0.03;
	public static inline var SHIT_HEALTH:Float = -0.03;
	public static inline var MISS_HEALTH:Float = -0.04;

	public var isGhostTapping:Bool = true;

	var control:Controls;

	public function new() {
		control = Main.controls;
	}

	public function handleInput(i:Int, noteController:NoteController, charId:String):Note {
		if (!control.getInputNotes()[i])
			return null;

		var note = noteController.getHittableNote(charId, i);
		if (note != null && justPressed(i)) {
			note.wasGoodHit = true;
			note.kill();
		}
		return note;
	}

	public function isPlayerHit(charStrums:Array<game.objects.sprites.notes.StrumNote>, charId:String, noteController:NoteController, gameAudio:GameAudio, playStateConfig:PlayStateConfig,i):Note {
		var note = handleInput(i, noteController, charId);
		if (isPressed(i)) {
			if (note != null) {
				charStrums[i].playAnim('confirm' + i, true);
			} else if (justPressed(i)) {
				charStrums[i].playAnim('press' + i, true);
				gameAudio.onMiss();
				playStateConfig.health += noteController.getHealthDrain(note);
				/*
					if (!isGhostTapping) {
				}*/
			}
		} else {
			// miss Note detection yep
			for (note in noteController.notes.members) {
				if (note == null || !note.alive || !note.mustPress)
					continue;
				if (note.strum == charStrums[i] && note.tooLate) {
					note.alpha = 0.3;
					gameAudio.onMiss();
					playStateConfig.health += noteController.getHealthDrain(note);
				}
			}
			charStrums[i].playAnim('static' + i, true);
		}

		// sustain holding
		for (sustain in noteController.sustains.members) {
			if (sustain == null || !sustain.alive || !sustain.mustPress)
				continue;
			if (sustain.strum != charStrums[i])
				continue;

			var isActive = core.rhythm.RhythmCore.songPosition >= sustain.strumTime
				&& core.rhythm.RhythmCore.songPosition <= sustain.strumTime + sustain.length;

			if (isActive && isPressed(i)) {
				sustain.isHeld = true;
				charStrums[i].playAnim('confirm' + i, true);
			}
		}

		return note;
	}

	public function isCPUHit(charStrums:Array<game.objects.sprites.notes.StrumNote>, noteController:NoteController, charId:String, i:Int) {
		var note = noteController.getHittableNote(charId, i, false);

		if (note != null) {
			charStrums[i].playAnim('confirm' + i, true);
			note.wasGoodHit = true;
			note.kill();
		}
	}

	public function justPressed(i:Int):Bool
		return control.justPressedNote(i);

	public function isPressed(i:Int):Bool
		return control.getInputNotes()[i];
}

package game.controllers;

import game.objects.sprites.notes.Note;
import game.controllers.NoteController;
import core.rhythm.audio.GameAudio;
import core.config.Controls;

class InputController {
	public var isGood:Bool = false;

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
			// note.kill();
		}
		return note;
	}

	public function isPlayerHit(charStrums:Array<game.objects.sprites.notes.StrumNote>, charId:String, noteController:NoteController, gameAudio:GameAudio,
			playStateConfig:PlayStateConfig, i):Note {
		var note = handleInput(i, noteController, charId);
		if (isPressed(i)) {
			if (note != null) {
				var diff = Math.abs(note.strumTime - core.rhythm.RhythmCore.songPosition);
				var ratingType = noteController.getRatingForDiff(diff);

				if (ratingType != null) {
					playStateConfig.score += ratingType.score;
					playStateConfig.health += ratingType.health;

					playStateConfig.totalAccuracyWeight += ratingType.accuracyWeight;
					playStateConfig.totalNotesHit++;
					playStateConfig.accuracy = playStateConfig.totalAccuracyWeight / playStateConfig.totalNotesHit;

					note.rating = ratingType.rating;
					playStateConfig.rating = ratingType.rating;

					if (ratingType.miss == true)
						playStateConfig.combo = 0;
					else
						playStateConfig.combo++;
				}

				note.kill();
				charStrums[i].playAnim('confirm' + i, true);
			} else if (justPressed(i)) {
				charStrums[i].playAnim('press' + i, true);
				/*
					if (!isGhostTapping) { */
				playStateConfig.misses++;
				gameAudio.onMiss();
				playStateConfig.health += noteController.getHealthDrain(null);
				playStateConfig.combo = 0;
				// }
			}
		} else {
			// miss Note detection yep
			for (note in noteController.notes.members) {
				if (note == null || !note.alive || !note.mustPress)
					continue;
				if (note.strum == charStrums[i] && note.tooLate) {
					note.canBeHit = false;
					note.alpha = 0.4;
					gameAudio.onMiss();
					playStateConfig.health += noteController.getHealthDrain(null);
					playStateConfig.misses++;
					playStateConfig.combo = 0;
					note.tooLate = false;
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

			var worstWindow = noteController.getWorstWindow();
			var isActive = core.rhythm.RhythmCore.songPosition >= sustain.strumTime - worstWindow;
			var parentHit = sustain.parentNote == null || sustain.parentNote.wasGoodHit;
			if (isActive && isPressed(i) && parentHit) {
				sustain.isHeld = true;
				charStrums[i].playAnim('confirm' + i, true);
			} else if (!isPressed(i)) {
				sustain.isHeld = false;
				//playStateConfig.health += noteController.getHealthDrain(null);
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

package game.controllers;

import game.objects.sprites.notes.Note;
import game.controllers.NoteController;
import core.rhythm.audio.GameAudio;
import core.config.Controls;

class InputController {
	public var isGood:Bool = false;

	public var isGhostTapping:Bool = true;

	public var control:Controls;

	public var isMiss:Void->Void = function() {};

	public function new() {
		control = core.ConfigMain.controls;
	}

	public function isPlayerHit(charStrums:Array<game.objects.sprites.notes.StrumNote>, charId:String, noteController:NoteController, gameAudio:GameAudio,
			playStateConfig:PlayStateConfig, i):Void {
		var isPressed = control.getGroupInput("noteKeys")[i];

		if (isPressed) {
			var songPos = core.rhythm.RhythmCore.songPosition;
			for (sustain in noteController.sustains.members) {
				if (sustain == null || !sustain.alive || !sustain.mustPress)
					continue;
				if (sustain.strum != charStrums[i])
					continue;
				if (sustain.isSustainEnd)
					continue;

				var canHold = songPos >= sustain.strumTime - 50 && songPos <= sustain.strumTime + sustain.length;
				if (canHold) {
					sustain.isHeld = true;
					charStrums[i].playAnim('confirm' + i, false);
				}
			}
		} else { // release key
			for (sustain in noteController.sustains.members) {
				if (sustain == null || !sustain.alive || !sustain.mustPress || sustain.strum != charStrums[i])
					continue;

				var songPos = core.rhythm.RhythmCore.songPosition;
				if (sustain.isHeld && songPos < (sustain.strumTime + sustain.length)) {
					sustain.wasMissed = true;
					sustain.canBeHit = false;
					onMiss(playStateConfig, noteController, gameAudio);
				}

				sustain.isHeld = false;
			}

			for (note in noteController.notes.members) {
				if (note == null || !note.alive || !note.mustPress || note.wasMissed)
					continue;
				if (note.strum != charStrums[i] || !note.tooLate)
					continue;

				note.wasMissed = true;
				note.canBeHit = false;

				onMiss(playStateConfig, noteController, gameAudio);
			}

			charStrums[i].playAnim('static' + i, true);
		}
	}

	public function attemptHit(charStrums:Array<game.objects.sprites.notes.StrumNote>, charId:String, noteController:NoteController, gameAudio:GameAudio,
			playStateConfig:PlayStateConfig, i:Int):Note {
		var hasActiveSustain = false;
		for (sustain in noteController.sustains.members) {
			if (sustain == null || !sustain.alive || !sustain.mustPress || sustain.strum != charStrums[i])
				continue;
			if (sustain.isHeld) {
				hasActiveSustain = true;
				break;
			}
		}

		var bestNote:Note = null;
		var bestDiff:Float = Math.POSITIVE_INFINITY;

		for (note in noteController.notes.members) {
			if (note == null || !note.alive || !note.mustPress || note.wasGoodHit || note.wasMissed)
				continue;
			if (note.strum != charStrums[i])
				continue;

			var diff = Math.abs(note.strumTime - core.rhythm.RhythmCore.songPosition);
			if (diff <= noteController.worstWindow && diff < bestDiff) {
				bestDiff = diff;
				bestNote = note;
			}
		}

		if (bestNote != null) {
			// HIT REAL
			var ratingType = noteController.getRatingForDiff(bestDiff);

			if (ratingType != null) {
				playStateConfig.score += ratingType.score;
				playStateConfig.health += ratingType.health;

				playStateConfig.totalAccuracyWeight += ratingType.accuracyWeight;
				playStateConfig.totalNotesHit++;
				playStateConfig.accuracy = playStateConfig.totalAccuracyWeight / playStateConfig.totalNotesHit;

				bestNote.rating = ratingType.rating;
				playStateConfig.rating = ratingType.rating;

				if (ratingType.miss == true)
					playStateConfig.combo = 0;
				else
					playStateConfig.combo++;
			}

			bestNote.wasGoodHit = true;
			bestNote.kill();
			charStrums[i].playAnim('confirm' + i, false);

			if (ratingType.splash)
				noteController.spawnSplash(charStrums[i], i, bestNote.noteType);

			return bestNote;
		} else if (!hasActiveSustain) {
			charStrums[i].playAnim('press' + i, true);
			if (!isGhostTapping) {
				onMiss(playStateConfig, noteController, gameAudio);
			}
		}

		return null;
	}

	public function onMiss(playStateConfig:PlayStateConfig, noteController:NoteController, gameAudio:GameAudio) {
		if (isMiss != null)
			isMiss();
		gameAudio.onMiss();
		playStateConfig.health += noteController.getHealthDrain(null);
		playStateConfig.score += noteController.getMissScore();
		playStateConfig.misses++;
		playStateConfig.combo = 0;
	}

	public function isCPUHit(charStrums:Array<game.objects.sprites.notes.StrumNote>, noteController:NoteController, charId:String, i:Int) {
		var note = noteController.getHittableNote(charId, i, false);
		if (note != null) {
			charStrums[i].playAnim('confirm' + i, false);
			note.wasGoodHit = true;
			note.kill();
		}
	}
}

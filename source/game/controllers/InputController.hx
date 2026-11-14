package game.controllers;

import core.enums.InputType;
import core.audio.GameAudio;
import game.controllers.NoteController;
import game.objects.sprites.notes.Note;
import game.objects.sprites.notes.StrumNote;
import game.objects.sprites.notes.NoteSustain;

class InputController {
	public var isGhostTapping:Bool = true;
	public var control:Controls;

	public var onNoteHit:Note->Void = function(_) {};
	public var onMiss:Void->Void = function() {};
	public var onSustainDrop:Void->Void = function() {};

	public function new() {
		control = core.ConfigMain.controls;
	}

	// player
	public function processLane(i:Int, strum:StrumNote, noteController:NoteController, gameAudio:GameAudio, playStateConfig:PlayStateConfig):InputType {
		if (control.justPressed("noteKeys", i))
			return onPressed(i, strum, noteController, gameAudio, playStateConfig);

		if (control.getGroupInput("noteKeys")[i])
			return onHeld(i, strum, noteController);

		if (control.justReleased("noteKeys", i))
			return onReleased(i, strum, noteController, gameAudio, playStateConfig);

		return Nothing;
	}

	public function applyMiss(playStateConfig:PlayStateConfig, noteController:NoteController, gameAudio:GameAudio, ?missedNote:Note):Void {
		onMiss();
		gameAudio.onMiss();
		noteController.noteTypeManager?.onNoteMiss(missedNote);
		playStateConfig.health += noteController.getHealthDrain(missedNote);
		playStateConfig.score += noteController.getMissScore();
		playStateConfig.misses++;
		playStateConfig.combo = 0;
		playStateConfig.totalNotes++;
	}

	function onPressed(i:Int, strum:StrumNote, nc:NoteController, audio:GameAudio, cfg:PlayStateConfig):InputType {
		var note = findBestNote(strum, nc);
		if (note != null) {
			registerHit(i, note, strum, nc, cfg);
			onNoteHit(note);
			nc.noteTypeManager?.onNoteHit(note);
			return NoteHit(note);
		}
		strum.playAnim('press$i', true);
		if (!isGhostTapping)
			applyMiss(cfg, nc, audio);
		return GhostTap;
	}

	function onHeld(i:Int, strum:StrumNote, nc:NoteController):InputType {
		var songPos = core.rhythm.RhythmCore.songPosition;
		var heldSustain:NoteSustain = null;
		for (sustain in nc.sustains.members) {
			if (!isSustainOnStrum(sustain, strum))
				continue;
			var canHold = sustain.wasNoteHit && songPos >= sustain.strumTime - 50 && songPos <= sustain.strumTime + sustain.length;
			if (canHold) {
				if (!sustain.isHeld)
					nc.spawnHoldSplash(strum, i, sustain.noteType);
				sustain.isHeld = true;
				strum.playAnim('confirm$i', false);
				heldSustain = sustain;
			} else if (sustain.isHeld) {
				// sustain finished
				sustain.isHeld = false;
				nc.stopHoldSplash(strum);
			}
		}
		return heldSustain != null ? SustainHeld(heldSustain) : Nothing;
	}

	function onReleased(i:Int, strum:StrumNote, nc:NoteController, audio:GameAudio, cfg:PlayStateConfig):InputType {
		var songPos = core.rhythm.RhythmCore.songPosition;
		var dropped = false;
		for (sustain in nc.sustains.members) {
			if (!isSustainOnStrum(sustain, strum) || !sustain.isHeld)
				continue;
			sustain.isHeld = false;
			nc.stopHoldSplash(strum);
			var remaining = (sustain.strumTime + sustain.length) - songPos;
			if (remaining > 50) {
				sustain.wasMissed = true;
				sustain.canBeHit = false;
				onSustainDrop();
				applyMiss(cfg, nc, audio);
				dropped = true;
			}
		}
		strum.playAnim('static$i', true);
		return dropped ? SustainDropped : Nothing;
	}

	// Find the note closest to the current `strumTime` within the hit range.
	function findBestNote(strum:StrumNote, nc:NoteController):Null<Note> {
		var best:Note = null;
		var bestDiff = Math.POSITIVE_INFINITY;
		var songPos = core.rhythm.RhythmCore.songPosition;
		for (note in nc.notes.members) {
			if (note == null || !note.alive || !note.mustPress || note.wasGoodHit || note.wasMissed)
				continue;
			if (note.strum != strum)
				continue;
			var diff = Math.abs(note.strumTime - songPos);
			if (diff <= nc.worstWindow && diff < bestDiff) {
				bestDiff = diff;
				best = note;
			}
		}
		return best;
	}

	// note hit: scoring, sustains, animation, splash.
	function registerHit(i:Int, note:Note, strum:StrumNote, nc:NoteController, cfg:PlayStateConfig):Void {
		var diff = Math.abs(note.strumTime - core.rhythm.RhythmCore.songPosition);
		var rating = nc.getRatingForDiff(diff);
		if (rating != null) {
			cfg.score += rating.score;
			cfg.health += rating.health;
			note.rating = rating.name;
			cfg.rating = rating.name;
			cfg.hitNotes++;
			cfg.totalNotes++;
			cfg.combo = rating.miss == true ? 0 : cfg.combo + 1;
		}
		note.wasGoodHit = true;
		for (sustain in nc.sustains.members)
			if (sustain != null && sustain.alive && sustain.strum == strum && sustain.strumTime == note.strumTime)
				sustain.wasNoteHit = true;
		note.kill();
		strum.playAnim('confirm$i', false);
		strum.confirmHoldTimer = -1;
		if (rating?.splash)
			nc.spawnSplash(strum, i, note.noteType);
	}

	inline function isSustainOnStrum(s:NoteSustain, strum:StrumNote):Bool
		return s != null && s.alive && s.mustPress && s.strum == strum && !s.isSustainEnd;

	// cpu
	public function isCPUHit(charStrums:Array<StrumNote>, noteController:NoteController, charId:String, i:Int, mustPress:Bool = false):Void {
		var note = noteController.getHittableNote(charId, i, mustPress);
		if (note != null) {
			charStrums[i].startConfirm();
			charStrums[i].applyShader(noteController.noteSkinData);
			note.wasGoodHit = true;
			note.kill();
		}
	}
}

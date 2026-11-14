package core.enums;

enum InputType {
	Nothing; // Key not pressed, nothing to be done.
	NoteHit(note:game.objects.sprites.notes.Note); // You press the key at exactly the right note.
	GhostTap; // Key pressed but no note within range.
	SustainHeld(sustain:game.objects.sprites.notes.NoteSustain); // Hit sustain active.
	SustainDropped; // Sustain released before finishing.
}

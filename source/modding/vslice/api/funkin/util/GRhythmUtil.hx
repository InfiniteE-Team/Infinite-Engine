package funkin.util;

// same math as the engine's notes -JloorDev
@:keep
class GRhythmUtil {
	public static var HIT_WINDOW_MS:Float = 160;

	public static function getNoteY(strumTime:Float, scrollSpeed:Float, isDownscroll:Bool = false, ?conductor:Dynamic):Float {
		var y = (strumTime - core.rhythm.RhythmCore.songPosition) * Constants.PIXELS_PER_MS * scrollSpeed;
		return isDownscroll ? -y : y;
	}

	public static function processWindow(note:Dynamic, ?isControlled:Bool = true):Void {
		var time:Float = note.noteData.time;
		var pos = core.rhythm.RhythmCore.songPosition;
		if (pos > time + HIT_WINDOW_MS) {
			note.mayHit = false;
			note.tooEarly = false;
			note.hasMissed = true;
		} else if (pos > time - HIT_WINDOW_MS) {
			note.mayHit = true;
			note.tooEarly = false;
		} else {
			note.mayHit = false;
			note.tooEarly = true;
		}
	}
}

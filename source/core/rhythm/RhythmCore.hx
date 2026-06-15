package core.rhythm;

class RhythmCore {
	public static var bpm:Float = 100.0;
	public static var crochet:Float = 600.0;
	public static var stepInMs:Float = 150;

	public static var songPosition:Float = 0;

	public static function changeBPM(newBPM:Float):Void {
		bpm = newBPM;
		crochet = 60000.0 / bpm;
		stepInMs = crochet * 0.25;
	}

	public static function pause(gameAudio:core.rhythm.audio.GameAudio, windowMod):Void {
		FlxG.sound.pause();
		if (gameAudio.inst != null)
			gameAudio.inst.pause();
		if (gameAudio.vocals != null)
			gameAudio.vocals.pause();
		if (windowMod != null)
			windowMod.pauseWindow();
	}

	public static function resume(gameAudio:core.rhythm.audio.GameAudio, windowMod):Void {
		FlxG.sound.resume();
		if (gameAudio.inst != null) {
			gameAudio.inst.resume();
			if (gameAudio.vocals != null) {
				// gameAudio.vocals.time = gameAudio.inst.time;
				gameAudio.vocals.resume();
			}
		}
		if (windowMod != null)
			windowMod.resumeWindow();
	}

    public static function reset(bpm:Float)
    {
        songPosition = 0;
		changeBPM(bpm);
    }
}

package core.rhythm;

class RhythmCore {
	public static var bpm:Float = 100.0;
	public static var crochet:Float = 600.0;
	public static var stepInMs:Float = 150;

	public static var songPosition:Float = 0;

	public static var timeSignatures:Array<Float> = [];

	public static function changeBPM(newBPM:Float):Void {
		bpm = newBPM;
		crochet = 60000.0 / bpm;
		stepInMs = crochet * 0.25;
	}

	public static function changeSignaturesBPM() {}

	public static function pause(gameAudio:core.rhythm.audio.GameAudio):Void {
		FlxG.sound.pause();
		if (gameAudio.inst != null)
			gameAudio.inst.pause();
		if (gameAudio.vocals != null)
			gameAudio.vocals.pause();
	}

	public static function resume(gameAudio:core.rhythm.audio.GameAudio):Void {
		FlxG.sound.resume();
		if (gameAudio.inst != null)
			gameAudio.inst.resume();
		if (gameAudio.vocals != null)
			gameAudio.vocals.resume();
	}

	public static function reset(bpm:Float):Void {
		songPosition = 0;
		changeBPM(bpm);
	}
}

package core.rhythm.audio;

class MasterAudio {
	// Class for the Audio General Manager
	public static function playMenu(path:String, volume:Float = 1, ?bpm:Float = 102, ?forceRestart:Bool = false):Void {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing || forceRestart) {
			RhythmCore.changeBPM(bpm);
			FlxG.sound.playMusic(path, volume, true);
		}
	}
}

package core.rhythm.audio;

class MasterAudio {
	// Class for the Audio General Manager
	public static function playMenu(path:String, volume:Float = 1, ?bpm:Float = 102, ?forceRestart:Bool = false):Void {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing || forceRestart) {
			RhythmCore.changeBPM(bpm);
			FlxG.sound.playMusic(path, volume, true);
		}
	}

	// Load Stream for better ram use
	public static function playSong(path:String, volume:Float = 1, ?bpm:Float = 102, ?forceRestart:Bool = false):Void {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing || forceRestart) {
			if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }

			RhythmCore.changeBPM(bpm);

			FlxG.sound.music = new Sound(MUSIC, path);

			FlxG.sound.music.volume = volume;

			FlxG.sound.music.play();
		}
	}
}

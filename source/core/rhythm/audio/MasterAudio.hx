package core.rhythm.audio;

class MasterAudio {
	public static var currentTrackPath:String = "";

	// Class for the Audio General Manager
	public static function playMenu(path:String, volume:Float = 1, ?bpm:Float = 102):Void {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing || currentTrackPath != path) {
			var absPath = sys.FileSystem.absolutePath(path);
			var oflSound = core.rhythm.audio.Sound.streamedCache.get(absPath);
			if (oflSound == null && sys.FileSystem.exists(path))
				oflSound = openfl.media.Sound.fromFile(path);
			currentTrackPath = path;
			RhythmCore.changeBPM(bpm);
			FlxG.sound.playMusic(oflSound, volume, true);
		}
	}

	// Load Stream for better ram use
	public static function playSong(path:String, volume:Float = 1, ?bpm:Float = 102):Void {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing || currentTrackPath != path) {
			currentTrackPath = path;
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

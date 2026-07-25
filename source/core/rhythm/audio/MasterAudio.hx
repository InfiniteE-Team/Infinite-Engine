package core.rhythm.audio;
class MasterAudio {
	// Class for the Audio General Manager
	public static function playMenu(path:String, volume:Float = 1, ?bpm:Float = 102):Void {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			RhythmCore.changeBPM(bpm);
			FlxG.sound.playMusic(Paths.getPath(path, 'music'), volume, true);
		}
	}
}

package core.rhythm.audio;

class MasterAudio {
	public static var currentTrackPath:String = "";

	// Class for the Audio General Manager
	public static function playMenu(path:String, volume:Float = 1, ?bpm:Float = 102):Void {
		if (FlxG.sound.music != null && FlxG.sound.music.playing && currentTrackPath == path)
			return;

		currentTrackPath = path;
		RhythmCore.changeBPM(bpm);

		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
			FlxG.sound.music = null;
		}

		var absPath = sys.FileSystem.absolutePath(path);
		var cached = Sound.isStreamable(absPath) ? Sound.openStream(absPath) : Sound.streamedCache.get(absPath);

		if (cached != null) {
			launchMusic(cached, volume);
		} else {
			sys.thread.Thread.create(function():Void {
				var oflSound:openfl.media.Sound = null;
				try {
					#if lime_cffi
					var buf = lime.media.AudioBuffer.fromFile(absPath);
					if (buf != null)
						oflSound = openfl.media.Sound.fromAudioBuffer(buf);
					#else
					oflSound = openfl.media.Sound.fromFile(absPath);
					#end
				} catch (e:Dynamic) {}

				haxe.MainLoop.runInMainThread(function():Void {
					if (oflSound != null && !Sound.streamedCache.exists(absPath))
						Sound.streamedCache.set(absPath, oflSound);
					if (currentTrackPath == path)
						launchMusic(Sound.streamedCache.get(absPath), volume);
				});
			});
		}
	}

	static function launchMusic(oflSound:openfl.media.Sound, volume:Float):Void {
		if (oflSound == null)
			return;
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}
		var sound = new flixel.sound.FlxSound();
		sound.load(oflSound, true);
		sound.volume = volume;
		sound.looped = true;
		sound.persist = true;
		FlxG.sound.music = sound;
		FlxG.sound.music.play(true);
	}
}

package core.rhythm.audio;

enum abstract SoundType(String) from String to String {
	var SOUND = "SOUND";
	var MUSIC = "MUSIC";
}

class Sound extends flixel.sound.FlxSound {
	public static var streamedCache:Map<String, openfl.media.Sound> = new Map();

	public var soundType:SoundType;
	public var soundPath:String;

	public var onLoaded:() -> Void;

	public function new(type:SoundType, path:String) {
		super();
		this.soundType = type;
		this.soundPath = path;
		onSoundStreamed(type, path);
	}

	public function onSoundStreamed(type:SoundType, path:String) {
		if (path == null)
			return;

		var absPath = sys.FileSystem.absolutePath(path);

		if (!sys.FileSystem.exists(absPath)) {
			trace('Sound: not found: $absPath');
			return;
		}

		var oflSound = streamedCache.get(absPath);
		if (oflSound == null) {
			openfl.media.Sound.loadFromFile(absPath).onComplete(function(sound:openfl.media.Sound) {
				if (sound != null) {
					streamedCache.set(absPath, sound);
					var savedCallback = onComplete;
					load(sound);
					onComplete = savedCallback;
					if (onLoaded != null)
						onLoaded();
				}
			}).onError(function(error) {
				trace('Sound: Error when loading the audio file: $error');
			});
			return;
		}

		load(oflSound);
	}

	public var playbackRate(default, set):Float = 1.0;

	private function set_playbackRate(value:Float):Float {
		playbackRate = value;
		if (this.playing) {
			this.pitch = playbackRate;
		}
		return playbackRate;
	}

	public static function clearGlobalCache():Void {
		for (snd in streamedCache) {
			@:privateAccess
			if (snd.__buffer != null) {
				snd.__buffer.dispose();
				snd.__buffer = null;
			}
			snd.close();
		}

		if (streamedCache != null)
			streamedCache.clear();
	}

	override public function destroy():Void {
		soundPath = null;

		super.destroy();
	}
}

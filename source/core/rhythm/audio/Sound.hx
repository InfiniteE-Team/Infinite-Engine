package core.rhythm.audio;

enum abstract SoundType(String) from String to String {
	var SOUND = "SOUND";
	var MUSIC = "MUSIC";
}

class Sound extends flixel.sound.FlxSound {
	public static var streamedCache:Map<String, String> = new Map<String, String>();

	public var soundType:SoundType;
	public var soundPath:String;

	public function new(type:SoundType, path:String) {
		super();
		this.soundType = type;
		this.soundPath = path;
		onSoundStreamed(type, path);
	}

	public function onSoundStreamed(type:SoundType, path:String) {
		if (path == null) {
			trace('Sound path not found for "$path"');
			return;
		}

		if (!streamedCache.exists(path))
			streamedCache.set(type, path);

		loadStreamed(streamedCache.get(type));
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
        if (streamedCache != null) {
            streamedCache.clear();
            trace("Sound Cache cleaned!");
        }
    }

	override public function destroy():Void {
		soundPath = null;

		super.destroy();
	}
}

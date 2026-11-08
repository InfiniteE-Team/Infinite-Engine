package core.audio;

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

		var oflSound = isStreamable(absPath) ? openStream(absPath) : streamedCache.get(absPath);
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

	public static function isStreamable(absPath:String):Bool
		return #if lime_vorbis absPath.toLowerCase().endsWith('.ogg') #else false #end;

	// ogg plays as a stream instead of decoding it all to RAM, a stream can't be shared so it isn't cached -JloorDev
	public static function openStream(absPath:String):Null<openfl.media.Sound> {
		#if lime_vorbis
		var vorbis = lime.media.vorbis.VorbisFile.fromFile(absPath);
		if (vorbis != null)
			return openfl.media.Sound.fromAudioBuffer(lime.media.AudioBuffer.fromVorbisFile(vorbis));
		#end
		return null;
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

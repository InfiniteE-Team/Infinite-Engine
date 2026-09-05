package core.rhythm.audio;

import flixel.sound.FlxSound;
import funkin.vis.dsp.SpectralAnalyzer;
import lime.media.AudioSource;

class AudioAnalyzer {
	public var analyzer:SpectralAnalyzer;
	public var levels(default, null):Array<Bar> = [];

	public static inline var BAR_COUNT:Int = 3;

	public function new(sound:Sound, barCount:Int = 3) {
		var source = getSource(sound);
		if (source == null)
			return;

		analyzer = new SpectralAnalyzer(source, barCount, 0.08, 20);
		analyzer.minDb = -80;
		analyzer.maxDb = -20;
		analyzer.minFreq = 40;
		analyzer.maxFreq = 16000;
	}

	public function update():Void {
		if (analyzer == null)
			return;
		levels = analyzer.getLevels(levels);
	}

	public function getLevel(band:Int):Float {
		if (band < 0 || band >= levels.length)
			return 0.0;
		return levels[band].value;
	}

	public function getPeak(band:Int):Float {
		if (band < 0 || band >= levels.length)
			return 0.0;
		return levels[band].peak;
	}

	static function getSource(sound:FlxSound):Null<AudioSource> {
		if (sound == null)
			return null;
		if (!sound.playing)
			return null;
		try {
			#if (openfl >= "9.3.2")
			var channel = @:privateAccess sound._channel;
			if (channel == null)
				return null;
			return @:privateAccess channel.__audioSource;
			#else
			var channel = @:privateAccess sound._channel;
			if (channel == null)
				return null;
			return @:privateAccess channel.__source;
			#end
		} catch (e) {
			return null;
		}
	}
}

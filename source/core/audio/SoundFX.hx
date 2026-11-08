package core.audio;

import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class SoundFX extends FlxSound {
	public function new() {
		super();
	}

	public static function randomPitch(soundPath:String, ?minPitch:Float = 0.8, ?maxPitch:Float = 1, ?volume:Float = 1.0, ?varyVolume:Bool = false):FlxSound {
		var sound = FlxG.sound.play(soundPath, volume);
		if (sound != null) {
			sound.pitch = FlxG.random.float(minPitch, maxPitch);
			if (varyVolume)
				sound.volume = volume * FlxG.random.float(0.85, 1.15);
		}
		return sound;
	}

	public static function pitchSlide(soundPath:String, fromPitch:Float = 0.5, toPitch:Float = 1.0, duration:Float = 0.5, volume:Float = 1.0):FlxSound {
		var sound = FlxG.sound.play(soundPath, volume);
		if (sound != null) {
			sound.pitch = fromPitch;
			FlxTween.tween(sound, {pitch: toPitch}, duration, {ease: FlxEase.quadOut});
		}
		return sound;
	}

	public static function reverb(soundPath:String, echoes:Int = 3, delay:Float = 0.08, decayVolume:Float = 0.5, volume:Float = 1.0):Void {
		FlxG.sound.play(soundPath, volume);
		for (i in 1...echoes + 1) {
			var echoVolume = volume * Math.pow(decayVolume, i);
			var echoDelay = delay * i;
			new flixel.util.FlxTimer().start(echoDelay, (_) -> {
				var echo = FlxG.sound.play(soundPath, echoVolume);
				if (echo != null)
					echo.pitch = 1.0 - (i * 0.04);
			});
		}
	}

	public static function distorted(soundPath:String, volume:Float = 1.0):FlxSound {
		var sound = FlxG.sound.play(soundPath, volume);
		if (sound != null)
			sound.pitch = FlxG.random.float(1.1, 1.3);
		return sound;
	}

	public static function playPanned(soundPath:String, pan:Float = 0.0, volume:Float = 1.0):FlxSound {
		var sound = FlxG.sound.play(soundPath, volume);
		if (sound != null)
			sound.pan = pan;
		return sound;
	}

	public static function playSpatial(soundPath:String, sourceX:Float, volume:Float = 1.0):FlxSound {
		var pan:Float = ((sourceX / FlxG.width) * 2.0) - 1.0;
		pan = Math.max(-1.0, Math.min(1.0, pan));
		return playPanned(soundPath, pan, volume);
	}

	public static function stutter(soundPath:String, times:Int = 3, interval:Float = 0.06, volume:Float = 1.0):Void {
		for (i in 0...times) {
			new flixel.util.FlxTimer().start(interval * i, (_) -> {
				FlxG.sound.play(soundPath, volume * (1.0 - (i * 0.15)));
			});
		}
	}

	public static function playFull(soundPath:String, volume:Float = 1.0, pitch:Float = 1.0, pan:Float = 0.0):FlxSound {
		var sound = FlxG.sound.play(soundPath, volume);
		if (sound != null) {
			sound.pitch = pitch;
			sound.pan = pan;
		}
		return sound;
	}
}

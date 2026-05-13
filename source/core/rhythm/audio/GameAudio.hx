package core.rhythm.audio;

import core.assets.Paths;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;

class GameAudio extends FlxTypedGroup<FlxSound> {
	// Class for the game audio manager
	public var inst:FlxSound;
	public var vocals:FlxSound;

	public function new() {
		super();
	}

	public function loadSong(needVoices:Bool = true,onfinish:()->Void):Void {
		forEachAlive(function(s:FlxSound) { s.stop(); s.destroy(); });
		clear();
		inst = null;
		vocals = null;
		
		inst = audio('Inst',onfinish);
		add(inst);
		if (needVoices) {
			vocals = audio('Voices',onfinish);
			add(vocals);
		}
	}

	public function audio(path:String,onfinish:()->Void):FlxSound {
		var sound:FlxSound = FlxG.sound.load(Paths.getPath(path, 'songAudio'));
		sound.onComplete = onfinish;
		return sound;
	}

	public function playAll():Void {
		if (vocals != null) {
			vocals.time = inst.time;
		}
		forEachAlive(function(s:FlxSound) s.play());
	}

	public function pauseAll():Void {
		forEachAlive(function(s:FlxSound) s.pause());
	}

	public function stopAll():Void {
		forEachAlive(function(s:FlxSound) s.stop());
	}

	public function resyncVocals():Void {
		if (vocals == null || !vocals.playing || inst == null)
			return;
		if (Math.abs(vocals.time - inst.time) < 20)
			return;
		
		inst.pause();
		vocals.time = inst.time;
		inst.play();
		vocals.play();
	}

	override public function destroy():Void {
		super.destroy();
		inst = null;
		vocals = null;
	}
}

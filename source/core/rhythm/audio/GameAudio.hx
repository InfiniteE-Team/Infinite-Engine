package core.rhythm.audio;

import core.assets.Paths;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import core.json.song.SongData.SongConfig;

class GameAudio extends FlxTypedGroup<FlxSound> {
	// Class for the game audio manager
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var soundMisses:Array<FlxSound> = [];

	public function new() {
		super();
	}

	public function loadSong(needVoices:Bool = true, onfinish:() -> Void):Void {
		forEachAlive(function(s:FlxSound) {
			s.stop();
			s.destroy();
		});
		clear();
		inst = null;
		vocals = null;
		for (miss in soundMisses) {
            miss.destroy();
        }
        soundMisses = [];

		inst = audio('Inst', onfinish);
		if (inst != null)
			add(inst);

		if (needVoices) {
			vocals = audio('Voices', onfinish);
			if (vocals != null)
				add(vocals);
		}

		for (i in 1...3) {
            var miss = new FlxSound();
            miss.loadEmbedded(Paths.getPath('gameplay/misses/missnote' + i,"sound"), false, false, null);
            FlxG.sound.list.add(miss);
            soundMisses.push(miss);
        }
	}

	public function audio(path:String, onfinish:() -> Void):FlxSound {
		var resolvedPath = Paths.getPath(path, 'songAudio');
		if (resolvedPath == null) {
			trace('GameAudio path not found for "$path"');
			return null;
		}
		var sound = new FlxSound();
		sound.loadEmbedded(resolvedPath, false, false, onfinish);
		sound.volume = 1.0;
		return sound;
	}

	public function playAll():Void {
		if (inst == null)
			return;
		if (vocals != null) {
			vocals.time = inst.time;
		}
		forEachAlive(function(s:FlxSound) if (s != null)
			s.play());
	}

	public function volumenVocs(SONG:SongConfig, isMiss:Bool, elapsed:Float) {
		if (vocals == null) return;

		if (!SONG.vocSeparated || SONG.needVoices) {
			if (isMiss)
				vocals.volume = 0;
			else if (vocals.volume < 1)
				vocals.volume = Math.min(1, vocals.volume + elapsed);
		}
	}

	public function onMiss():Void {
        if (vocals != null) {
            vocals.volume = 0;
        }
        
        if (soundMisses.length > 0) {
            var randomMiss = FlxG.random.getObject(soundMisses);
			randomMiss.volume = FlxG.random.float(0.1, 0.2);
            randomMiss.play(true);
        }
    }

	public function pauseAll():Void {
		forEachAlive(function(s:FlxSound) s.pause());
	}

	public function resumeAll():Void {
		forEachAlive(function(s:FlxSound) s.resume());
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
		for (miss in soundMisses) {
            miss.destroy();
        }
        soundMisses = null;
	}
}

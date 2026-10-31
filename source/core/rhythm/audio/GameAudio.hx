package core.rhythm.audio;

import core.assets.Paths;
import flixel.sound.FlxSound;
import core.json.song.SongData.SongConfig;

// Class for the gameplay audio
class GameAudio extends flixel.group.FlxGroup.FlxTypedGroup<FlxSound> {
	public var inst:Sound;
	public var vocals:Sound;
	public var vocalsGroup:Array<Sound> = [];
	public var vocalsMap:Map<String, Sound> = new Map();
	public var onInstReady:() -> Void;

	public var soundMisses:Array<FlxSound> = [];

	public function new() {
		super();
	}

	public function loadSong(SONG:SongConfig, needVoices:Bool = true, onfinish:() -> Void):Void {
		forEachAlive(function(s:FlxSound) {
			s.stop();
			s.destroy();
		});
		clear();
		inst = null;
		vocals = null;
		vocalsGroup = [];
		vocalsMap = new Map();
		for (miss in soundMisses) {
			FlxG.sound.list.remove(miss, true);
			miss.destroy();
		}
		soundMisses = [];

		inst = audio('Inst' + SONG?.instPrefix, onfinish);
		if (inst != null)
			add(inst);

		if (needVoices)
			vocalsSeparated(SONG, null);

		for (i in 1...3) {
			var miss = new FlxSound();
			miss.load(Paths.getPath('gameplay/misses/missnote' + i, "sound"), false);
			miss.looped = false;
			FlxG.sound.list.add(miss);
			soundMisses.push(miss);
		}
	}

	function vocalsSeparated(SONG:SongConfig, onfinish:() -> Void) {
		if (SONG == null)
			return;

		var stems:Array<{id:String, file:String}> = [];

		if (SONG.vocs != null) {
			var used:Array<String> = [];
			for (i in 0...SONG.chars.length) {
				var file = voiceStem(i < SONG.vocs.length ? SONG.vocs[i] : '');
				if (file != null && !used.contains(file)) {
					used.push(file);
					stems.push({id: SONG.chars[i].id, file: file});
				}
			}
		} else {
			var used:Array<String> = [];
			for (char in SONG.chars) {
				var found = false;
				for (candidate in [char.name, char.id]) {
					if (candidate == null || candidate == '')
						continue;
					var file = 'Voices-' + candidate;
					if (Paths.getPath(file, 'songAudio') != null && !used.contains(file)) {
						used.push(file);
						stems.push({id: char.id, file: file});
						found = true;
						break;
					}
				}
			}
			if (stems.length == 0)
				stems.push({id: 'default', file: 'Voices' + SONG.vocPrefix});
		}

		for (s in stems) {
			var v = audio(s.file, onfinish);
			if (v == null)
				continue;
			vocalsGroup.push(v);
			vocalsMap.set(s.id, v);
			add(v);
		}
		if (vocalsGroup.length > 0)
			vocals = vocalsGroup[0];
	}

	public function playAll():Void {
		if (inst == null)
			return;
		for (voice in vocalsGroup)
			voice.time = inst.time;
		forEachAlive(function(s:FlxSound) if (s != null)
			s.play());
	}

	public function volumeVocs(SONG:SongConfig, isMiss:Bool, elapsed:Float) {
		if (vocalsGroup.length == 0)
			return;

		for (voice in vocalsGroup) {
			if (voice == null)
				continue;

			if (SONG.vocs == null || SONG.needVoices) {
				if (isMiss)
					voice.volume = 0;
				else if (voice.volume < 1)
					voice.volume = Math.min(1, voice.volume + elapsed);
			}
		}
	}

	public function resyncVocals():Void {
		if (inst == null)
			return;

		for (voice in vocalsGroup) {
			if (voice == null || vocals == null || !vocals.playing)
				continue;

			if (Math.abs(voice.time - inst.time) > 20) {
				voice.time = inst.time;
				if (!voice.playing)
					voice.play();
			}
		}
	}

	public function onMiss():Void {
		for (voice in vocalsGroup) {
			if (voice != null)
				voice.volume = 0;
		}

		if (soundMisses.length > 0) {
			var randomMiss = FlxG.random.getObject(soundMisses);
			randomMiss.volume = FlxG.random.float(0.1, 0.2);
			randomMiss.play(true);
		}
	}

	function voiceStem(stem:String):String {
		var name = stem;
		while (Paths.getPath(name, 'songAudio') == null && name.lastIndexOf('-') > 0)
			name = name.substr(0, name.lastIndexOf('-'));
		return name;
	}

	public function audio(path:String, onfinish:() -> Void):Sound {
		var sound = new Sound(MUSIC, Paths.getPath(path, 'songAudio'));
		sound.volume = 1.0;
		if (onfinish != null) {
			sound.onLoaded = () -> {
				sound.onComplete = onfinish;
			};
		}
		return sound;
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

	public function setVocalVolumeByName(charName:String, vol:Float):Void {
		if (vocalsMap.exists(charName)) {
			vocalsMap.get(charName).volume = vol;
		}
	}

	public function setTime(time:Float):Void {
		if (inst != null)
			inst.time = time;
		for (v in vocalsGroup) {
			if (v != null)
				v.time = time;
		}
	}

	override public function destroy():Void {
		super.destroy();
		inst = null;
		vocals = null;
		vocalsGroup = null;
		vocalsMap = null;

		for (miss in soundMisses) {
			FlxG.sound.list.remove(miss, true);
			miss.destroy();
		}
		soundMisses = null;
	}
}

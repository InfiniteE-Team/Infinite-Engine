package core.json.extensions;

typedef AudioData = {
	var name:String;
	var path:String;
	var ?volume:Float; // 0.0 – 1.0
	var ?bpm:Float;
	var ?looped:Bool;
	var ?fadeIn:Float;
	var ?fadeOut:Float;
	var ?startTime:Float;
	var ?event:String; // "start" | "hover" | "click" | "destroy"
	var ?pitch:Float;
	var ?channel:String; // "music" | "sfx" | "voice" | "ambient"
}

class AudioConfig {
	public function new() {}

	public static function playElementAudio(audio:AudioData, ?folder:String = ''):Void {
		if (audio == null)
			return;
		var isMusic = audio.channel == 'music' || audio.looped == true;
		if (isMusic) {
			FlxG.sound.playMusic(Paths.getPath(folder + audio.path, 'music'), audio.volume ?? 1.0, audio.looped ?? true);
			if (audio.fadeIn != null)
				FlxG.sound.music.fadeIn(audio.fadeIn, 0, audio.volume ?? 1.0);
		} else {
			var sfx = FlxG.sound.play(Paths.getPath(folder + audio.path, 'sound'), audio.volume ?? 1.0, audio.looped ?? false);
			if (sfx != null && audio.pitch != null)
				sfx.pitch = audio.pitch;
		}
	}

	public function loadNameVars(data:AudioData) {
		var name = data.name;
	}
}

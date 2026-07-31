package core.config;

class SaveScore {
	public static var songScores:Map<String, Int> = new Map();

	public function new() {}

	public static function saveSong(song:String, score:Int, diff:Int):Void {
		var daSong:String = formaterSong(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score)
				setScore(daSong, score, diff);
		} else
			setScore(daSong, score, diff);
	}

	public static function saveWeek(name:String, score:Int, diff:Int):Void {
		var daWeek = formaterSong(name, diff);

		if (songScores.exists(daWeek)) {
			if (songScores.get(daWeek) < score)
				setScore(daWeek, score, diff);
		} else
			setScore(daWeek, score, diff);
	}

	public static function formaterSong(curSong:String, diff:Int):String {
		var nameSong = curSong + '-' + core.rhythm.DiffsUtils.difficulties[diff];
		return nameSong;
	}

	static function setScore(song:String, score:Int, diff:Int):Void {
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	static function getScore(song:String, diff:Int):Int {
		if (!songScores.exists(formaterSong(song, diff)))
			setScore(formaterSong(song, diff), 0, diff);
		return songScores.get(formaterSong(song, diff));
	}

	public static function load():Void {
		if (FlxG.save.data.songScores != null) {
			songScores = FlxG.save.data.songScores;
		}
	}
}

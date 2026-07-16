package;

import flixel.text.FlxTextBorderStyle;

class FreeplayState extends ScriptedStateBase {
	var curSelected:Int = 0;
	var songs:Array<FreeplayData> = [];

	public function new() {
		super();
	}

	override public function create() {
		script.loadTypedef("FreeplayData");

		super.create();

		if (freeplayData != null && freeplayData.songData != null) {
			for (i in 0...songs.songData.length) {
				var song:FlxText = new FlxText(30, 30 + (i * 30), FlxG.width, songs.songData.song[i]);
				song.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFFFFFFFF, "left");
				song.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
				song.antialiasing = SaveData.data.antialiasing;
				song.scrollFactor.set(0, 0);
				add(song);
			}
		}
	}
}

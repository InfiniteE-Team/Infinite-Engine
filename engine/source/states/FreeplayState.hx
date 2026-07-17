package;

import flixel.text.FlxTextBorderStyle;

class FreeplayState extends ScriptedStateBase {
	var curSelected:Int = 0;
	var songs:Array<FlxText> = [];
	var icons:Array<game.objects.sprites.Icon> = [];
	var freeplayData:core.json.engine.FreeplayData;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		freeplayData = FormatJson.readJson(Paths.getPath('songs/listSong', 'json'));

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getPath('menus/menuBG', 'image'));
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		if (freeplayData != null && freeplayData.songData != null) {
			for (i in 0...freeplayData.songData.length) {
				var song:FlxText = new FlxText(100, 100 + (i * 60), FlxG.width, freeplayData.songData[i].song);
				song.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFFFFF, "left");
				song.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
				song.antialiasing = SaveData.data.antialiasing;
				song.scrollFactor.set(0, 0);
				songs.push(song);
				add(song);

				var icon:game.objects.sprites.Icon = new game.objects.sprites.Icon(false, null, freeplayData.songData[i].icon);
				icon.x = song.x + song.width;
				icon.y = song.y;
				icon.scrollFactor.set(0, 0);
				icons.push(icon);
				add(icon);
			}
		}
	}
}
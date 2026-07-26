package;

import states.LoadingState;
import game.PlayStateConfig;
import states.MusicBeatState;
import game.objects.sprites.Icon;
import flixel.tweens.FlxTween.FlxTweenType;
import flixel.text.FlxTextBorderStyle;

class FreeplayState extends ScriptState {
	var curSelected:Int = 0;
	var songs:Array<FlxText> = [];
	var icons:Array<Icon> = [];
	var freeplayData:core.json.engine.FreeplayData;

	var acceptOption:Bool = false;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		MasterAudio.playMenu('menus/freakyMenu/freakyMenu', 0.6, 102);

		freeplayData = FormatJson.readJson(Paths.getPath('songs/listSong', 'json'));

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getPath('menus/menuBG', 'image'));
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		if (freeplayData != null && freeplayData.songData != null) {
			for (i in 0...freeplayData.songData.length) {
				var song:FlxText = new FlxText(100, 100 + (i * 125), 0, freeplayData.songData[i].song);
				song.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFFFFF, "left");
				song.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
				song.antialiasing = SaveData.data.antialiasing;
				song.ID = i;
				song.scrollFactor.set(0, 0);
				songs.push(song);
				add(song);

				var icon:Icon = new Icon(false, null, freeplayData.songData[i].icon);
				if (icon != null) {
					icon.scale.set(0.85, 0.85);
					icon.x = song.x + song.width;
					icon.y = song.y / 2 + (i * 60);
					icon.scrollFactor.set(0, 0);
					icon.updateHitbox();
					icons.push(icon);
					add(icon);
				}
			}
		} else {
			var noExists = new FlxText(0, FlxG.height / 2 - 35, FlxG.width, "There are no songs! - Create your music list in 'songs/listSong.json'");
			noExists.setFormat(Paths.getPath('Funkin.otf', 'font'), 24, 0xFFFFB2B2, "center");
			noExists.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			noExists.antialiasing = SaveData.data.antialiasing;
			noExists.alpha = 0;
			noExists.scrollFactor.set(0, 0);
			add(noExists);

			FlxTween.tween(noExists, {alpha: 1}, 1, {type: FlxTweenType.PINGPONG});
		}

		changeSelection(0);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		if (freeplayData.songData.length > 0) {
			if (Controls.UI_UP)
				changeSelection(-1);
			if (Controls.UI_DOWN)
				changeSelection(1);
		}

		if (Controls.ACCEPT) {
			acceptOption = true;
			FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
			FlxG.camera.flash(0xFFFFFFFF, 0.4);

			var songSelected:String = freeplayData.songData[curSelected].song;

			PlayStateConfig.isStoryMode = false;

			new FlxTimer().start(1, function() {
				MusicBeatState.switchState(() -> new LoadingState(songSelected, 0));
			});
		}

		if (Controls.BACK) {
			acceptOption = true;
			ScriptClass.switchState('MainMenuState');
		}
	}

	function changeSelection(change:Int = 0):Void {
		curSelected += change;

		FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));

		if (curSelected < 0)
			curSelected = freeplayData.songData.length - 1;
		if (curSelected >= freeplayData.songData.length)
			curSelected = 0;

		for (item in songs) {
			if (item.ID == curSelected) {
				item.alpha = 1.0;
			} else {
				item.alpha = 0.6;
			}
		}
	}
}

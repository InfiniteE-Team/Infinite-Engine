package;

import utils.InfiniteUtil;
import states.LoadingState;
import game.PlayStateConfig;
import states.MusicBeatState;
import core.config.SaveScore;
import core.rhythm.DiffsUtils;
import game.objects.sprites.Icon;
import flixel.tweens.FlxTween.FlxTweenType;
import flixel.text.FlxTextBorderStyle;
import flixel.math.FlxMath;

class FreeplayState extends ScriptState {
	var curSelected:Int = 0;
	var songs:Array<FlxText> = [];
	var icons:Array<Icon> = [];
	var freeplayData:core.json.engine.FreeplayData;

	var album:FunkinSprite;

	// song score & lerp variables
	var scoreTxt:FlxText;
	var songScore:Int = 0;
	var intendedScore:Int = 0;

	// difficulty
	var curDiff:Int = 0;
	var diffTxt:FlxText;

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

				var charData = FormatJson.readJson(Paths.getPath('data/characters/' + freeplayData.songData[i].icon, 'json'));
				var icon:Icon = new Icon(false, charData);
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

		scoreTxt = new FlxText(0, 10, 0, 'SCORE:');
		scoreTxt.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFE7E7, "center");
		scoreTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		scoreTxt.antialiasing = SaveData.data.antialiasing;
		scoreTxt.scrollFactor.set(0, 0);
		add(scoreTxt);

		diffTxt = new FlxText(0, scoreTxt.y + scoreTxt.height, 0, 'HARD');
		diffTxt.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFE7E7, "center");
		diffTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		diffTxt.antialiasing = SaveData.data.antialiasing;
		diffTxt.scrollFactor.set(0, 0);
		add(diffTxt);

		album = new FunkinSprite(0, 100);
		album.antialiasing = SaveData.data.antialiasing;
		add(album);

		changeSelection(0);
		changeDifficulty(0);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		songScore = Math.floor(FlxMath.lerp(songScore, intendedScore, FlxMath.bound(elapsed * 16, 0, 1)));

		scoreTxt.text = 'SCORE: ' + InfiniteUtil.formatNumber(songScore);
		scoreTxt.x = (FlxG.width - scoreTxt.width) / 2;

		if (acceptOption)
			return;

		if (freeplayData.songData.length > 0) {
			if (Controls.UI_UP)
				changeSelection(-1);
			if (Controls.UI_DOWN)
				changeSelection(1);
		}

		if (DiffsUtils.difficulties.length > 0) {
			if (Controls.UI_LEFT)
				changeDifficulty(-1);
			if (Controls.UI_RIGHT)
				changeDifficulty(1);
		}

		if (Controls.ACCEPT) {
			acceptOption = true;
			FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
			FlxG.camera.flash(0xFFFFFFFF, 0.4);

			var songSelected:String = freeplayData.songData[curSelected].song;

			PlayStateConfig.isStoryMode = false;

			new FlxTimer().start(1, function() {
				MusicBeatState.switchState(() -> new LoadingState(songSelected, curDiff));
			});
		}

		if (Controls.BACK) {
			acceptOption = true;
			ScriptClass.switchState('MainMenuState');
		}

		for (icon in icons) {
			if (icon.scale.x > 0.85) {
				icon.scale.x = FlxMath.lerp(icon.scale.x, 0.85, elapsed * 12);
				icon.scale.y = FlxMath.lerp(icon.scale.y, 0.85, elapsed * 12);
			}
		}
	}

	function changeDifficulty(change:Int = 0):Void {
		curDiff += change;

		if (curDiff < 0)
			curDiff = DiffsUtils.difficulties.length - 1;
		if (curDiff >= DiffsUtils.difficulties.length)
			curDiff = 0;

		DiffsUtils.getDifficulty(freeplayData.songData[curSelected].song);

		diffTxt.text = '< ' + DiffsUtils.difficulties[curDiff].toUpperCase() + ' >';
		diffTxt.x = (FlxG.width - diffTxt.width) / 2;

		updateScore();
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

		updateScore();

		if (album != null) {
			album.loadGraphic(Paths.getPath('menus/freeplay/albums/' + freeplayData.songData[curSelected].album, 'image'));
			album.x = FlxG.width * 0.9 - album.width;
		}
	}

	function updateScore():Void {
		intendedScore = SaveScore.getScore(freeplayData.songData[curSelected].song, curDiff);
	}

	override function beatHit(beat:Float) {
		super.beatHit(beat);
		for (icon in icons) {
			if (icon != null) {
				if (icon.bumpInBeats && Math.floor(beat % icon.stepTempo) == 0) {
					icon.scale.set(1.05, 1.05);
				}
			}
		}
	}

	override public function destroy() {
		super.destroy();
		freeplayData = null;
		album = null;
		songs = null;
		icons = null;
	}
}

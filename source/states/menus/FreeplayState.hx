package states.menus;

import flixel.FlxSprite;
import utils.InfiniteUtil;
import states.LoadingState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import game.PlayStateConfig;
import states.MusicBeatState;
import core.config.SaveScore;
import core.rhythm.DiffsUtils;
import flixel.tweens.FlxTween;
import core.assets.FunkinSprite;
import game.objects.sprites.Icon;
// filters
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.filters.GlowFilter;
import flixel.util.FlxColor;
import openfl.filters.BitmapFilterQuality;

class FreeplayState extends states.MusicBeatState {
	public static var curSelected:Int = 0;

	var songs:Array<FlxSprite> = [];
	var icons:Array<Icon> = [];
	var freeplayData:core.json.engine.FreeplayData;

	var album:FunkinSprite;

	// song score & lerp variables
	var scoreTxt:FlxText;
	var songScore:Int = 0;
	var intendedScore:Int = 0;

	var box:FlxSprite;

	// difficulty
	public static var curDiff:Int = 0;

	var diffTxt:FlxText;

	var acceptOption:Bool = false;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		#if HSCRIPT_ALLOWED
		initScript();
		script.executeAll();
		script.call("onCreate", []);
		#end

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/freakyMenu/freakyMenu', 'music'), 0.6, 102);

		freeplayData = FormatJson.readJson(Paths.getPath('songs/listSong', 'json'));

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getPath('menus/menuBG', 'image'));
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		if (freeplayData != null && freeplayData.songData != null) {
			for (i in 0...freeplayData.songData.length) {
				var tf:TextField = new TextField();
				tf.autoSize = openfl.text.TextFieldAutoSize.LEFT;
				tf.text = freeplayData.songData[i].song;
				tf.setTextFormat(new TextFormat(Paths.getPath('5by7.ttf', 'font'), 42, 0xFFFFFFFF));
				tf.filters = [
					new openfl.filters.GlowFilter(FlxColor.fromString('#00ccff'), 1.0, 6, 6, 100, openfl.filters.BitmapFilterQuality.MEDIUM)
				];
				var bmp:openfl.display.BitmapData = new openfl.display.BitmapData(Math.ceil(tf.width + 12), Math.ceil(tf.height + 12), true, 0x00000000);
				bmp.draw(tf);
				var song:FlxSprite = new FlxSprite(300 - (i * 50), 100 + (i * 125));
				song.loadGraphic(bmp);
				song.antialiasing = SaveData.data.antialiasing;
				song.ID = i;
				songs.push(song);
				add(song);

				var charData = FormatJson.readJson(Paths.getPath('data/characters/' + freeplayData.songData[i].icon, 'json'));
				var icon:Icon = new Icon(false, charData);
				if (icon != null) {
					icon.scale.set(0.85, 0.85);
					icon.x = (song.x - (i * 50)) - song.width;
					icon.y = song.y / 2 + (i * 60);
					icon.updateHitbox();
					icons.push(icon);
					add(icon);
				}
			}
		} else {
			var noExists = new FlxText(0, FlxG.height / 2 - 35, FlxG.width, "There are no songs! - Create your music list in 'songs/listSong.json'");
			noExists.setFormat(Paths.getPath('5by7_b.ttf', 'font'), 24, 0xFFFFB2B2, "center");
			noExists.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			noExists.antialiasing = SaveData.data.antialiasing;
			noExists.alpha = 0;
			noExists.scrollFactor.set(0, 0);
			add(noExists);

			FlxTween.tween(noExists, {alpha: 1}, 1, {type: FlxTweenType.PINGPONG});
		}

		box = new FlxSprite(770, -80).makeGraphic(1, 1, 0xFF0F0F0F);
		box.scale.set(590, 870);
		box.updateHitbox();
		box.angle = 10;
		add(box);

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

		scoreTxt.x = 720 + (590 / 2) - (scoreTxt.fieldWidth / 2);
		scoreTxt.y = FlxG.height * 0.76;

		diffTxt.y = FlxG.height * 0.7;

		album = new FunkinSprite(0, 100);
		album.antialiasing = SaveData.data.antialiasing;
		add(album);

		if (freeplayData != null && freeplayData.songData != null && freeplayData.songData.length > 0) {
			if (curSelected >= freeplayData.songData.length)
				curSelected = 0;
			if (curSelected < 0)
				curSelected = 0;
		}

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end

		changeSelection(0);
		changeDifficulty(0);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		script.call("onUpdate", [elapsed]);
		#end

		songScore = Math.floor(FlxMath.lerp(songScore, intendedScore, FlxMath.bound(elapsed * 16, 0, 1)));

		scoreTxt.text = 'SCORE: ' + InfiniteUtil.formatNumber(songScore);

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

			new FlxTimer().start(1, function(tmr:FlxTimer) {
				MusicBeatState.switchState(() -> new LoadingState(songSelected, curDiff));
			});
		}

		if (Controls.BACK) {
			acceptOption = true;
			core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/freakyMenu/freakyMenu', 'music'), 0.6, 102, true);
			modding.scripting.types.ScriptClass.switchState('MainMenuState');
		}

		for (icon in icons) {
			if (icon.scale.x > 0.85) {
				icon.scale.x = FlxMath.lerp(icon.scale.x, 0.85, elapsed * 12);
				icon.scale.y = FlxMath.lerp(icon.scale.y, 0.85, elapsed * 12);
			}
		}

		#if HSCRIPT_ALLOWED
		script.call("postUpdate", [elapsed]);
		#end
	}

	function changeDifficulty(change:Int = 0):Void {
		curDiff += change;

		if (curDiff < 0)
			curDiff = DiffsUtils.difficulties.length - 1;
		if (curDiff >= DiffsUtils.difficulties.length)
			curDiff = 0;

		DiffsUtils.getDifficulty(freeplayData.songData[curSelected].song);

		diffTxt.text = '< ' + DiffsUtils.difficulties[curDiff].toUpperCase() + ' >';
		diffTxt.x = 925;

		updateScore();
	}

	function changeMusic():Void {
		if (freeplayData == null || freeplayData.songData == null || freeplayData.songData[curSelected] == null)
			return;

		var songSelected:String = freeplayData.songData[curSelected].song;
		var bpm:Float = freeplayData.songData[curSelected].bpm;

		if (songSelected != null) {
			core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('songs/' + songSelected + '/audio/Inst.ogg'), 0.6, bpm, true);
		}
	}

	function changeSelection(change:Int = 0):Void {
		curSelected += change;

		FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));

		if (curSelected < 0)
			curSelected = freeplayData.songData.length - 1;
		if (curSelected >= freeplayData.songData.length)
			curSelected = 0;

		changeMusic();

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
			album.x = FlxG.width * 0.91 - album.width;
		}
	}

	function updateScore():Void {
		@:privateAccess
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

		songs = null;
		icons = null;
		freeplayData = null;
		album = null;

		FlxG.bitmap.clearUnused();
	}
}

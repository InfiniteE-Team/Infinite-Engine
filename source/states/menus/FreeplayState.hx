package states.menus;

import flixel.FlxSprite;
import utils.InfiniteUtil;
import states.LoadingState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import game.PlayStateConfig;
import core.config.SaveScore;
import core.rhythm.DiffsUtils;
import flixel.tweens.FlxTween;
import core.assets.FunkinSprite;
import game.objects.sprites.Icon;
import flixel.addons.display.FlxBackdrop;
// filters
import openfl.filters.GlowFilter;
import openfl.filters.BitmapFilterQuality;

class FreeplayState extends MusicBeatState {
	public static var curSelected:Int = 0;

	var bg:FlxBackdrop;
	var buildings:FlxBackdrop;

	var songs:Array<FlxSprite> = [];
	var icons:Array<Icon> = [];
	var freeplayData:core.json.engine.FreeplayData;

	var album:FunkinSprite;

	var artistTxt:FlxText;

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

		bg = new FlxBackdrop(Paths.getPath('menus/freeplay/bg', 'image'), flixel.util.FlxAxes.X);
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scale.set(0.25, 0.25);
		bg.scrollFactor.set(0, 0);
		bg.updateHitbox();
		bg.screenCenter();
		bg.velocity.set(-50, 0);
		add(bg);

		buildings = new FlxBackdrop(Paths.getPath('menus/freeplay/buildings', 'image'), flixel.util.FlxAxes.X);
		buildings.antialiasing = SaveData.data.antialiasing;
		buildings.scale.set(0.25, 0.25);
		buildings.scrollFactor.set(0, 0);
		buildings.updateHitbox();
		buildings.screenCenter();
		buildings.velocity.set(-150, 0);
		add(buildings);

		if (freeplayData != null && freeplayData.songData != null) {
			var cardImgPath:String = Paths.getPath('menus/freeplay/card', 'image');
			var charDataCache:Map<String, Dynamic> = new Map();
			for (i in 0...freeplayData.songData.length) {
				var card:FlxSprite = new FlxSprite().loadGraphic(cardImgPath);
				card.antialiasing = SaveData.data.antialiasing;
				card.ID = i;
				songs.push(card);
				add(card);

				var song:FlxText = new FlxText(300 - (i * 50), 100 + (i * 125), 0, freeplayData.songData[i].song);
				song.setFormat(Paths.getPath('5by7.ttf', 'font'), 42, 0xFFFFFFFF);
				@:privateAccess song.textField.filters = [
					new openfl.filters.GlowFilter(FlxColor.fromString('#00ccff'), 1.0, 6, 6, 100, BitmapFilterQuality.MEDIUM)
				];
				song.antialiasing = SaveData.data.antialiasing;
				song.ID = i;
				songs.push(song);
				add(song);

				card.x = song.x - 80;
				card.y = song.y - 50;

				var iconName:String = freeplayData.songData[i].icon;
				var charData = charDataCache.get(iconName);
				if (charData == null) {
					charData = FormatJson.readJson(Paths.getPath('data/characters/' + iconName, 'json'));
					charDataCache.set(iconName, charData);
				}
				var icon:Icon = new Icon(false, charData);
				if (icon != null) {
					icon.scale.set(0.85, 0.85);
					icon.x = (song.x - (i * 50)) - song.width;
					icon.y = song.y / 2 + (i * 60);
					icon.ID = i;
					icon.updateHitbox();
					icons.push(icon);
					add(icon);
				}
			}

			box = new FlxSprite(770, -80).makeGraphic(1, 1, 0xFF0F0F0F);
			box.scale.set(590, 870);
			box.updateHitbox();
			box.angle = 10;
			add(box);

			artistTxt = new FlxText(0, 0, 0, 'Artist: ??');
			artistTxt.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFE7E7, "center");
			artistTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			artistTxt.antialiasing = SaveData.data.antialiasing;
			artistTxt.scrollFactor.set(0, 0);
			add(artistTxt);

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

			artistTxt.x = 725 + (590 / 2) - artistTxt.width;
			artistTxt.y = FlxG.height * 0.64;

			scoreTxt.x = 720 + (590 / 2) - (scoreTxt.width / 2);
			scoreTxt.y = FlxG.height * 0.76;

			diffTxt.y = FlxG.height * 0.7;

			album = new FunkinSprite(0, 100, true);
			album.antialiasing = SaveData.data.antialiasing;
			add(album);
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

		if (songScore != intendedScore) {
			var newScore = Math.floor(FlxMath.lerp(songScore, intendedScore, FlxMath.bound(elapsed * 16, 0, 1)));
			if (newScore == songScore)
				newScore = intendedScore;
			songScore = newScore;
			if (freeplayData != null && freeplayData.songData != null)
				scoreTxt.text = 'SCORE: ' + InfiniteUtil.formatNumber(songScore);
		}

		if (acceptOption)
			return;

		if (freeplayData != null && freeplayData.songData.length > 0) {
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
				MusicBeatState.switchState(() -> new LoadingState(songSelected, curDiff), freeplayData.songData[curSelected].stickerPack ?? 'default');
			});
		}

		if (Controls.BACK) {
			acceptOption = true;
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
		if (freeplayData == null || freeplayData.songData == null)
			return;

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
			core.rhythm.audio.MasterAudio.playSong(Paths.getPath('songs/' + songSelected + '/audio/Inst.ogg'), 0.6, bpm);
		}
	}

	function changeSelection(change:Int = 0):Void {
		if (freeplayData == null || freeplayData.songData == null)
			return;

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

		for (item in icons) {
			if (item.ID == curSelected) {
				item.alpha = 1.0;
			} else {
				item.alpha = 0.6;
			}
		}

		if (freeplayData.songData[curSelected].artist != null)
			artistTxt.text = 'Artist: ' + freeplayData.songData[curSelected].artist;
		else
			artistTxt.text = 'Artist: ??';

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
		bg = null;
		buildings = null;

		FlxG.bitmap.clearUnused();
	}
}

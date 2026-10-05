package states.menus;

import flixel.FlxSprite;
import flixel.text.FlxText;
import states.menus.CreditsState;
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
import states.menus.objects.CardFreeplay;

class FreeplayState extends MusicBeatState {
	public static var curSelected:Int = 0;

	var bg:FlxBackdrop;
	var buildings:FlxBackdrop;

	var songs:Array<CardFreeplay> = [];
	var icons:Array<Icon> = [];
	var freeplayData:core.json.engine.FreeplayData;

	var album:FunkinSprite;
	var disk:FunkinSprite;

	var artistTxt:FlxText;

	// song score & lerp variables
	var scoreTxt:FlxText;
	var scoreSprite:FlxSprite;

	var songScore:Int = 213991;
	var intendedScore:Int = 0;

	var box:FlxSprite;

	// difficulty
	public static var curDiff:Int = 0;

	var diffTxt:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var acceptOption:Bool = false;

	var camFollow:flixel.FlxObject;

	public function new() {
		super();
	}

	// prevent crash when there are no songs... - JloorDev
	inline function hasSongs():Bool
		return freeplayData != null && freeplayData.songData != null && freeplayData.songData.length > 0;

	override public function create() {
		super.create();

		#if HSCRIPT_ALLOWED
		initScript();
		script.executeAll();
		script.call("onCreate", []);
		#end

		core.api.DiscordAPI.instance.setPresence({
			state: "In the Menu",
			details: "Infinite Engine",
			largeImageKey: "icon"
		});

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/freakyMenu/freakyMenu', 'music'), 0.6, 102);

		freeplayData = FormatJson.readJson(Paths.getPath('songs/listSong', 'json'));

		#if HSCRIPT_ALLOWED
		if (script.callCancellable("onCreateCancel", []))
			return;
		#end

		bg = new FlxBackdrop(Paths.getPath('menus/freeplay/bg', 'image'), flixel.util.FlxAxes.X);
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scale.set(0.25, 0.25);
		bg.scrollFactor.set(0, 0);
		bg.updateHitbox();
		bg.screenCenter();
		bg.velocity.set(-50, 0);
		add(bg);

		camFollow = new flixel.FlxObject(100, 150, 1, 1);
		add(camFollow);

		FlxG.camera.follow(camFollow, flixel.FlxCamera.FlxCameraFollowStyle.LOCKON, 0.08);

		buildings = new FlxBackdrop(Paths.getPath('menus/freeplay/buildings', 'image'), flixel.util.FlxAxes.X);
		buildings.antialiasing = SaveData.data.antialiasing;
		buildings.scale.set(0.25, 0.25);
		buildings.scrollFactor.set(0, 0);
		buildings.updateHitbox();
		buildings.screenCenter();
		buildings.velocity.set(-150, 0);
		add(buildings);

		if (freeplayData != null && freeplayData.songData != null) {
			var charDataCache:Map<String, Dynamic> = new Map();
			for (i in 0...freeplayData.songData.length) {
				var card:CardFreeplay = new CardFreeplay(200 - (i * 60), 30 + (i * 200), i);
				songs.push(card);
				add(card);

				var iconName:String = freeplayData.songData[i].icon;
				var charData = charDataCache.get(iconName);
				if (charData == null) {
					charData = FormatJson.readJson(Paths.getPath('data/characters/' + iconName, 'json'));
					charDataCache.set(iconName, charData);
				}

				var icon:Icon = new Icon(false, charData);
				if (icon != null) {
					icon.scale.set(0.48, 0.48);
					icon.updateHitbox();
					icon.alpha = 0.7;
					icon.x = card.x - icon.width + 165;
					icon.y = card.y / 2 + 60 + (i * 100);
					icon.ID = i;
					icons.push(icon);
					add(icon);
				}

				card.createCard(FlxG.width / 2 + (i * 200), FlxG.height / 2 - 100, freeplayData.songData[i].song, i);
			}

			box = new FlxSprite(700, 0).loadGraphic(Paths.getPath('menus/freeplay/leftBarBFGF', 'image'));
			box.scrollFactor.set(0, 0);
			add(box);

			artistTxt = new FlxText(0, 0, 590, 'Artist: ??');
			artistTxt.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFE7E7, "center");
			artistTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 3, 1);
			artistTxt.antialiasing = SaveData.data.antialiasing;
			artistTxt.scrollFactor.set(0, 0);
			add(artistTxt);

			scoreTxt = new FlxText(0, 10, 0, '0');
			scoreTxt.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFE7E7, "center");
			scoreTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 3, 1);
			scoreTxt.antialiasing = SaveData.data.antialiasing;
			scoreTxt.scrollFactor.set(0, 0);
			add(scoreTxt);

			scoreSprite = new FlxSprite(910, 499);
			scoreSprite.frames = Paths.getPath('menus/freeplay/Score Free Play', 'animated');
			scoreSprite.animation.addByPrefix('idle', 'idle', 24, true);
			scoreSprite.animation.play('idle');
			scoreSprite.scrollFactor.set(0, 0);
			scoreSprite.scale.set(0.25, 0.25);
			scoreSprite.updateHitbox();
			scoreSprite.antialiasing = SaveData.data.antialiasing;
			add(scoreSprite);

			diffTxt = new FlxSprite(950, scoreTxt.y + scoreTxt.height);
			diffTxt.frames = Paths.getPath('menus/freeplay/diffs/hard', 'animated');
			diffTxt.animation.addByPrefix('idle', 'idle', 24, true);
			diffTxt.animation.play('idle');
			diffTxt.scale.set(0.25, 0.25);
			diffTxt.updateHitbox();
			diffTxt.antialiasing = SaveData.data.antialiasing;
			diffTxt.scrollFactor.set(0, 0);
			add(diffTxt);

			leftArrow = new FlxSprite();
			leftArrow.frames = Paths.getPath('menus/freeplay/Arrow Left', 'animated');
			leftArrow.animation.addByPrefix('idle', 'idle', 24, true);
			leftArrow.animation.play('idle');
			leftArrow.scale.set(0.5, 0.5);
			leftArrow.updateHitbox();
			leftArrow.antialiasing = SaveData.data.antialiasing;
			leftArrow.scrollFactor.set(0, 0);
			add(leftArrow);

			rightArrow = new FlxSprite();
			rightArrow.frames = Paths.getPath('menus/freeplay/Arrow Right', 'animated');
			rightArrow.animation.addByPrefix('idle', 'idle', 24, true);
			rightArrow.animation.play('idle');
			rightArrow.scale.set(0.5, 0.5);
			rightArrow.updateHitbox();
			rightArrow.antialiasing = SaveData.data.antialiasing;
			rightArrow.scrollFactor.set(0, 0);
			add(rightArrow);

			artistTxt.x = FlxG.width * 0.58;
			artistTxt.y = FlxG.height * 0.64;

			scoreTxt.x = 1020;
			scoreTxt.y = FlxG.height * 0.7;

			diffTxt.y = 40;

			album = new FunkinSprite(0, 140, true);
			album.antialiasing = SaveData.data.antialiasing;
			album.scrollFactor.set(0, 0);
			album.scale.set(1.2, 1.2);
			album.updateHitbox();
			add(album);

			disk = new FunkinSprite(0, 100, true);
			disk.loadGraphic(Paths.getPath('menus/freeplay/OST SUPPORT', 'image'));
			disk.antialiasing = SaveData.data.antialiasing;
			disk.scrollFactor.set(0, 0);
			disk.scale.set(0.5, 0.5);
			disk.updateHitbox();
			disk.y = 90;
			disk.x = FlxG.width * 0.96 - disk.width;
			add(disk);
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

		var totalHeight:Float = (freeplayData != null && freeplayData.songData != null) ? freeplayData.songData.length * 125 + 300 : FlxG.height;
		var totalWidth:Float = (freeplayData != null && freeplayData.songData != null) ? FlxG.width + freeplayData.songData.length * 50 + 200 : FlxG.width;
		FlxG.camera.setScrollBoundsRect(-totalWidth, 0, totalWidth * 2, totalHeight, true);

		changeSelection(0);
		changeDifficulty(0);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		if (script.hasScripts)
			script.call("onUpdate", [elapsed]);
		#end

		if (songScore != intendedScore) {
			var newScore = Math.floor(FlxMath.lerp(songScore, intendedScore, FlxMath.bound(elapsed * 16, 0, 1)));
			if (newScore == songScore)
				newScore = intendedScore;
			songScore = newScore;
			if (freeplayData != null && freeplayData.songData != null)
				scoreTxt.text = InfiniteUtil.formatNumber(songScore);
		}

		if (acceptOption)
			return;

		if (hasSongs()) {
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

		if (Controls.ACCEPT && hasSongs()) {
			acceptOption = true;
			FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
			FlxG.camera.flash(0xFFFFFFFF, 0.4);

			var songSelected:String = freeplayData.songData[curSelected].song;

			PlayStateConfig.isStoryMode = false;

			#if HSCRIPT_ALLOWED
			script.call("onAccept", []);
			#end

			new FlxTimer().start(1, function(tmr:FlxTimer) {
				MusicBeatState.switchState(() -> new states.LoadingState(songSelected, curDiff), freeplayData.songData[curSelected].stickerPack ?? 'default');
			});
		}

		if (Controls.BACK) {
			#if HSCRIPT_ALLOWED
			script.call("onBack", []);
			#end
			acceptOption = true;
			modding.scripting.types.ScriptClass.switchState('MainMenuState');
		}

		for (icon in icons) {
			if (icon.scale.x > 0.48) {
				icon.scale.x = FlxMath.lerp(icon.scale.x, 0.48, elapsed * 12);
				icon.scale.y = FlxMath.lerp(icon.scale.y, 0.48, elapsed * 12);
			}
		}

		#if HSCRIPT_ALLOWED
		if (script.hasScripts)
			script.call("postUpdate", [elapsed]);
		#end
	}

	function changeDifficulty(change:Int = 0):Void {
		if (!hasSongs())
			return;

		#if HSCRIPT_ALLOWED
		script.call("onChangeDifficulty", [change]);
		#end

		curDiff += change;

		if (curDiff < 0)
			curDiff = DiffsUtils.difficulties.length - 1;
		if (curDiff >= DiffsUtils.difficulties.length)
			curDiff = 0;

		DiffsUtils.getDifficulty(freeplayData.songData[curSelected].song);

		curDiff = flixel.math.FlxMath.minInt(curDiff, DiffsUtils.difficulties.length - 1);

		if (diffTxt != null) {
			diffTxt.frames = Paths.getPath('menus/freeplay/diffs/' + DiffsUtils.difficulties[curDiff], 'animated');
			diffTxt.x = FlxG.width - diffTxt.width / 2 - 60;
			diffTxt.animation.addByPrefix('idle', 'idle', 24, true);
			diffTxt.animation.play('idle');
		}

		if (leftArrow != null) {
			leftArrow.x = diffTxt.x - leftArrow.width - 20;
			leftArrow.y = diffTxt.y + (diffTxt.height / 2) - (leftArrow.height / 2) - 65;
		}

		if (rightArrow != null) {
			rightArrow.x = diffTxt.x + diffTxt.width - 350;
			rightArrow.y = diffTxt.y + (diffTxt.height / 2) - (rightArrow.height / 2) - 65;
		}

		updateScore();

		changeMusic();

		#if HSCRIPT_ALLOWED
		script.call("postChangeDifficulty", [change]);
		#end
	}

	function changeMusic():Void {
		if (freeplayData == null || freeplayData.songData == null || freeplayData.songData[curSelected] == null)
			return;

		var songSelected:String = freeplayData.songData[curSelected].song;
		var bpm:Float = freeplayData.songData[curSelected].bpm;
		var diffName:String = DiffsUtils.difficulties.length > 0 ? DiffsUtils.difficulties[curDiff] : '';

		if (songSelected != null) {
			var diffInstPath = Paths.getPath('songs/$songSelected/audio/Inst-$diffName.ogg');
			var genericInstPath = Paths.getPath('songs/$songSelected/audio/Inst.ogg');

			var instPath = (diffName != '' && sys.FileSystem.exists(diffInstPath)) ? diffInstPath : genericInstPath;

			core.rhythm.audio.MasterAudio.playSong(instPath, 0.6, bpm);
		}

		#if HSCRIPT_ALLOWED
		script.call("onChangeMusic", []);
		#end
	}

	function changeSelection(change:Int = 0):Void {
		if (!hasSongs())
			return;

		#if HSCRIPT_ALLOWED
		script.call("onChangeSelection", [change]);
		#end

		curSelected += change;

		FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));

		if (curSelected < 0)
			curSelected = freeplayData.songData.length - 1;
		if (curSelected >= freeplayData.songData.length)
			curSelected = 0;

		for (item in songs) {
			if (item.ID == curSelected) {
				item.alpha = 1.0;
				item.card?.animation.play('selected');
			} else {
				item.alpha = 0.6;
				item.card?.animation.play('idle');
			}
		}

		for (item in icons) {
			if (item.ID == curSelected) {
				item.alpha = 0.7;
			} else {
				item.alpha = 0.6;
			}
		}

		if (artistTxt != null) {
			if (freeplayData.songData[curSelected].artist != null)
				artistTxt.text = 'Artist: ' + freeplayData.songData[curSelected].artist;
			else
				artistTxt.text = 'Artist: ??';

			artistTxt.x = FlxG.width * 0.58;
		}

		updateScore();

		if (album != null) {
			album.loadGraphic(Paths.getPath('menus/freeplay/albums/' + freeplayData.songData[curSelected].album, 'image'));
			album.x = FlxG.width * 0.925 - album.width;
		}

		if (songs.length > 0) {
			var targetCard = songs[curSelected];
			if (targetCard != null) {
				camFollow.x = targetCard.x + (targetCard.width / 2) + (FlxG.width * 0.15);
				camFollow.y = targetCard.y + (targetCard.height / 2) + (FlxG.height * 0.15);
			}
		}

		changeDifficulty(0);

		#if HSCRIPT_ALLOWED
		script.call("postChangeSelection", [change]);
		#end
	}

	function updateScore():Void {
		if (!hasSongs())
			return;

		@:privateAccess
		var saved:Null<Int> = SaveScore.getScore(freeplayData.songData[curSelected].song, curDiff);
		intendedScore = saved ?? 0;

		if (intendedScore == 0) {
			songScore = 0;
			scoreTxt.text = '0';
		}
	}

	override function beatHit(beat:Float) {
		super.beatHit(beat);
		for (icon in icons) {
			if (icon != null) {
				if (icon.bumpInBeats && Math.floor(beat % icon.stepTempo) == 0) {
					icon.scale.set(0.56, 0.56);
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
		diffTxt = null;
		leftArrow = null;
		rightArrow = null;

		FlxG.bitmap.clearUnused();
	}
}

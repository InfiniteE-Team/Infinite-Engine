package states.menus;

import sys.FileSystem;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import game.PlayStateConfig;
import states.LoadingState;
import core.config.SaveScore;
import core.rhythm.DiffsUtils;
import flixel.tweens.FlxTween.FlxTweenType;
import flixel.group.FlxGroup.FlxTypedGroup;

class StoryMenuState extends MusicBeatState {
	var weeks:Array<core.json.engine.storymenu.WeekData> = [];
	var curWeek:Int = 0;

	var acceptOption:Bool = false;

	var scoreText:FlxText;
	var descriptionText:FlxText;

	var charGroup:FlxTypedGroup<states.menus.objects.WeekCharacter>;

	var weekBanner:FlxSprite;

	var tracksTitleText:FlxText;
	var tracksGroup:FlxTypedGroup<FlxText>;

	var arrowLeft:FlxSprite;
	var arrowRight:FlxSprite;

	var diffSprite:FlxSprite;
	var diffLeft:FlxSprite;
	var diffRight:FlxSprite;

	public static var curDiff:Int = 0;

	var noWeeksText:FlxText;

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

		core.api.DiscordAPI.instance.setPresence({
			state: "In the Menu",
			details: "Infinite Engine",
			largeImageKey: "icon"
		});

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/freakyMenu/freakyMenu', 'music'), 0.6, 102);

		loadAllWeeks();

		buildBackground();
		buildTopBar();
		buildCharArea();
		buildWeekBanner();
		buildTracksPanel();

		if (weeks.length == 0) {
			buildNoWeeksWarning();
		} else {
			if (curWeek > 0)
				buildArrows();
			buildDiffSelector();
			refreshWeek(false);
			refreshDiff();
		}

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end
	}

	function buildBackground() {
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFDCC202);
		add(bg);

		var topBar = new FlxSprite().makeGraphic(FlxG.width, 70, FlxColor.BLACK);
		add(topBar);

		var bottomPanel = new FlxSprite().makeGraphic(FlxG.width, 275, FlxColor.BLACK);
		bottomPanel.y = FlxG.height / 2 + 125;
		add(bottomPanel);
	}

	function buildTopBar() {
		scoreText = new FlxText(10, 17, FlxG.width * 0.5, "LEVEL SCORE: 0");
		scoreText.setFormat(Paths.getPath('vcr.ttf', 'font'), 40, FlxColor.WHITE, "left");
		scoreText.antialiasing = SaveData.data.antialiasing;
		scoreText.scrollFactor.set(0, 0);
		add(scoreText);

		descriptionText = new FlxText(0, 17, FlxG.width - 10, "");
		descriptionText.setFormat(Paths.getPath('vcr.ttf', 'font'), 40, 0xFF878787, "right");
		descriptionText.antialiasing = SaveData.data.antialiasing;
		descriptionText.scrollFactor.set(0, 0);
		add(descriptionText);
	}

	function buildCharArea() {
		charGroup = new FlxTypedGroup<states.menus.objects.WeekCharacter>();
		add(charGroup);
	}

	function buildWeekBanner() {
		weekBanner = new FlxSprite();
		weekBanner.antialiasing = SaveData.data.antialiasing;
		weekBanner.scrollFactor.set(0, 0);
		add(weekBanner);
	}

	function buildTracksPanel() {
		tracksTitleText = new FlxText(-470, FlxG.height * 0.725, FlxG.width, "TRACKS");
		tracksTitleText.setFormat(Paths.getPath('vcr.ttf', 'font'), 30, 0xFFD93939, "center");
		tracksTitleText.antialiasing = SaveData.data.antialiasing;
		tracksTitleText.scrollFactor.set(0, 0);
		add(tracksTitleText);

		tracksGroup = new FlxTypedGroup<FlxText>();
		for (i in 0...10) {
			var t = new FlxText(-470, 0, FlxG.width, "");
			t.setFormat(Paths.getPath('vcr.ttf', 'font'), 22, 0xFFD93939, "center");
			t.antialiasing = SaveData.data.antialiasing;
			t.scrollFactor.set(0, 0);
			t.visible = false;
			tracksGroup.add(t);
		}
		add(tracksGroup);
	}

	function buildArrows() {
		#if HSCRIPT_ALLOWED
		script.call('onWeekArrows', []);
		#end

		arrowLeft = new FlxSprite();
		arrowLeft.frames = Paths.getPath('menus/storymenu/ui/arrows', 'animated');
		arrowLeft.animation.addByPrefix('idle', 'leftIdle', 24, true);
		arrowLeft.animation.addByPrefix('confirm', 'leftConfirm', 24, false);
		arrowLeft.animation.play('idle');
		arrowLeft.x = FlxG.width / 2 - arrowLeft.width / 2;
		arrowLeft.angle = 90;
		arrowLeft.y = -10;
		arrowLeft.scrollFactor.set(0, 0);
		arrowLeft.antialiasing = SaveData.data.antialiasing;
		add(arrowLeft);

		arrowRight = new FlxSprite();
		arrowRight.frames = Paths.getPath('menus/storymenu/ui/arrows', 'animated');
		arrowRight.animation.addByPrefix('idle', 'rightIdle', 24, true);
		arrowRight.animation.addByPrefix('confirm', 'rightConfirm', 24, false);
		arrowRight.animation.play('idle');
		arrowRight.x = FlxG.width / 2 - arrowRight.width / 2;
		arrowRight.y = FlxG.height - arrowRight.height - 20;
		arrowRight.angle = 90;
		arrowRight.scrollFactor.set(0, 0);
		arrowRight.antialiasing = SaveData.data.antialiasing;
		add(arrowRight);

		#if HSCRIPT_ALLOWED
		script.call('postWeekArrows', []);
		#end
	}

	function buildDiffSelector() {
		diffLeft = new FlxSprite();
		diffLeft.frames = Paths.getPath('menus/storymenu/ui/arrows', 'animated');
		diffLeft.animation.addByPrefix('idle', 'leftIdle', 24, true);
		diffLeft.animation.addByPrefix('confirm', 'leftConfirm', 24, false);
		diffLeft.animation.play('idle');
		diffLeft.scale.set(0.55, 0.55);
		diffLeft.updateHitbox();
		diffLeft.scrollFactor.set(0, 0);
		diffLeft.antialiasing = SaveData.data.antialiasing;
		add(diffLeft);

		diffSprite = new FlxSprite();
		diffSprite.antialiasing = SaveData.data.antialiasing;
		diffSprite.scrollFactor.set(0, 0);
		add(diffSprite);

		diffRight = new FlxSprite();
		diffRight.frames = Paths.getPath('menus/storymenu/ui/arrows', 'animated');
		diffRight.animation.addByPrefix('idle', 'rightIdle', 24, true);
		diffRight.animation.addByPrefix('confirm', 'rightConfirm', 24, false);
		diffRight.animation.play('idle');
		diffRight.scale.set(0.55, 0.55);
		diffRight.updateHitbox();
		diffRight.scrollFactor.set(0, 0);
		diffRight.antialiasing = SaveData.data.antialiasing;
		add(diffRight);
	}

	function buildNoWeeksWarning() {
		noWeeksText = new FlxText(0, FlxG.height / 2 - 35, FlxG.width, "¡Not exists weeks! — Create your data in 'data/storymenu/weeks/'");
		noWeeksText.setFormat(Paths.getPath('5by7_b.ttf', 'font'), 24, 0xFFFFB2B2, "center");
		noWeeksText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
		noWeeksText.antialiasing = SaveData.data.antialiasing;
		noWeeksText.alpha = 0;
		noWeeksText.scrollFactor.set(0, 0);
		add(noWeeksText);

		FlxTween.tween(noWeeksText, {alpha: 1}, 1, {type: FlxTweenType.PINGPONG});
	}

	function loadAllWeeks() {
		var resolved = Paths.getPath('data/storymenu/weeks');
		if (resolved == null || !FileSystem.exists(resolved))
			return;

		for (file in FileSystem.readDirectory(resolved)) {
			if (!file.endsWith('.json'))
				continue;
			var data:core.json.engine.storymenu.WeekData = FormatJson.readJson(Paths.getPath('data/storymenu/weeks/$file'));
			if (data != null)
				weeks.push(data);
		}

		weeks.sort((a, b) -> a.priority - b.priority);
	}

	function refreshWeek(animate:Bool = true) {
		if (weeks.length == 0)
			return;

		var data = weeks[curWeek];

		var totalScore:Int = 0;
		if (data.songs != null) {
			for (song in data.songs) {
				@:privateAccess
				totalScore += SaveScore.getScore(song.song, curDiff);
			}
		}
		scoreText.text = 'LEVEL SCORE: $totalScore';

		descriptionText.text = data.description != null ? data.description : "";

		charGroup.clear();
		if (data.chars != null) {
			var totalChars = data.chars.length;
			var spacing = 350;
			var startX = (FlxG.width / 2) - ((totalChars - 1) * spacing / 2) - 150;
			for (i in 0...totalChars) {
				var ch = new states.menus.objects.WeekCharacter(startX + i * spacing, 100, data.chars[i]);
				charGroup.add(ch);
			}
		}

		if (data.weekGraphic != null && data.weekGraphic != "") {
			var bannerPath = Paths.getPath('menus/storymenu/weeks/' + data.weekGraphic, 'image');
			if (bannerPath != null && FileSystem.exists(bannerPath)) {
				weekBanner.loadGraphic(bannerPath);
			} else {
				weekBanner.makeGraphic(400, 100, FlxColor.TRANSPARENT);
			}
		} else {
			weekBanner.makeGraphic(400, 100, FlxColor.TRANSPARENT);
		}
		weekBanner.screenCenter(X);
		weekBanner.y = FlxG.height / 2 + 150;

		var songs = data.songs != null ? data.songs : [];
		var members = tracksGroup.members;
		for (i in 0...members.length) {
			var t = members[i];
			if (i < songs.length) {
				t.text = songs[i].song != null ? songs[i].song.toUpperCase() : "???";
				t.y = FlxG.height * 0.77 + i * 30;
				t.visible = true;
			} else {
				t.visible = false;
			}
		}

		if (animate) {
			weekBanner.alpha = 0;
			FlxTween.tween(weekBanner, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		}
	}

	function refreshDiff() {
		if (weeks.length == 0)
			return;

		DiffsUtils.getDifficulty(weeks[curWeek].songs[0].song);

		if (curDiff >= DiffsUtils.difficulties.length)
			curDiff = DiffsUtils.difficulties.length - 1;
		if (curDiff < 0)
			curDiff = 0;

		var diffName = DiffsUtils.difficulties[curDiff].toLowerCase();
		var diffPath = Paths.getPath('menus/storymenu/difficulties/$diffName', 'image');
		if (diffPath != null && FileSystem.exists(diffPath))
			diffSprite.loadGraphic(diffPath);
		else
			diffSprite.makeGraphic(100, 40, FlxColor.TRANSPARENT);

		var centerX = FlxG.width / 2;
		var panelY = FlxG.height / 2 + 155;

		diffSprite.x = FlxG.width * 0.7;
		diffSprite.y = panelY;

		diffLeft.x = diffSprite.x - diffLeft.width - 10;
		diffLeft.y = diffSprite.y + (diffSprite.height / 2) - (diffLeft.height / 2);

		diffRight.x = diffSprite.x + diffSprite.width + 10;
		diffRight.y = diffLeft.y;

		if (weeks.length > 0) {
			var data = weeks[curWeek];
			@:privateAccess
			scoreText.text = 'LEVEL SCORE: ' + SaveScore.getScore(data.week, curDiff);
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		script.call("onUpdate", [elapsed]);
		#end

		if (acceptOption)
			return;

		handleInput();

		if (Controls.BACK) {
			acceptOption = true;
			FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
			modding.scripting.types.ScriptClass.switchState('MainMenuState');
		}

		#if HSCRIPT_ALLOWED
		script.call("postUpdate", [elapsed]);
		#end
	}

	function handleInput() {
		if (weeks.length == 0)
			return;

		if (Controls.UI_UP && curWeek > 0) {
			arrowLeft.animation.play('confirm', true);
			arrowLeft.animation.onFinish.addOnce(_ -> {
                arrowLeft.animation.play('idle');
            });
			curWeek--;
			refreshWeek();
			refreshDiff();
		} else if (Controls.UI_DOWN && curWeek < weeks.length - 1) {
			arrowRight.animation.play('confirm', true);
			arrowRight.animation.onFinish.addOnce(_ -> {
                arrowRight.animation.play('idle');
            });
			curWeek++;
			refreshWeek();
			refreshDiff();
		}

		if (Controls.UI_LEFT || Controls.UI_RIGHT) {
			var dir = Controls.UI_LEFT ? -1 : 1;
			curDiff += dir;
			if (curDiff < 0)
				curDiff = DiffsUtils.difficulties.length - 1;
			if (curDiff >= DiffsUtils.difficulties.length)
				curDiff = 0;

			var arrow = dir < 0 ? diffLeft : diffRight;
			arrow.animation.play('confirm', true);
			arrow.animation.onFinish.addOnce(_ -> {
                arrow.animation.play('idle');
            });

			refreshDiff();
		}

		if (Controls.ACCEPT) {
			acceptOption = true;
			startWeek();
		}
	}

	function startWeek() {
		var data = weeks[curWeek];
		if (data.songs == null || data.songs.length == 0) {
			acceptOption = false;
			return;
		}

		var midChar = charGroup.members[Std.int(charGroup.length / 2)];
		if (midChar != null && midChar.existsAnim('confirm'))
			midChar.acceptWeek();

		FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
		FlxG.camera.flash(0xFFFFFFFF, 0.4);

		PlayStateConfig.isStoryMode = true;
		PlayStateConfig.curWeek = curWeek;
		PlayStateConfig.storyWeekName = data.week;
		PlayStateConfig.storyScore = 0;
		PlayStateConfig.storyPlaylist = [for (s in data.songs) s.song];

		new FlxTimer().start(1, function(_) {
			var firstSong = PlayStateConfig.storyPlaylist[0];
			PlayStateConfig.storyPlaylist.shift();
			MusicBeatState.switchState(() -> new LoadingState(firstSong, curDiff), data.stickerPack ?? 'default');
		});
	}

	override public function beatHit(beat:Float) {
		super.beatHit(beat);

		for (item in charGroup)
			item.playAnim('idle');
	}

	override public function destroy() {
		super.destroy();

		weeks = null;
		charGroup = null;
		tracksGroup = null;
	}
}

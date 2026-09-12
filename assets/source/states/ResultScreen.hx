import game.PlayStateConfig;
import flixel.util.FlxGradient;
import openfl.display.BitmapData;
import openfl.geom.Matrix;

class ResultScreen extends ScriptState {
	var results:FunkinSprite;
	var rating:FlxSprite;
	var highscoreSprite:FunkinSprite;
	var scorePopin:FunkinSprite;

	var newHighScore:Bool = false;

	var acceptOption:Bool = false;

	var ratingPath:String = 'SS';

	var playStateConfig:PlayStateConfig;

	public function new(config:PlayStateConfig) {
		super();
		this.playStateConfig = config;
		ratingPath = calculateRank(config);
	}

	function calculateRank(config:PlayStateConfig):String {
		if (config.totalNotes <= 0)
			return 'F';

		var accuracy:Float = config.hitNotes / config.totalNotes;

		if (config.misses == 0 && accuracy == 1.0)
			return 'SS';
		if (config.misses == 0)
			return 'S';
		if (accuracy >= 0.90)
			return 'A';
		if (accuracy >= 0.75)
			return 'B';
		if (accuracy >= 0.60)
			return 'C';
		if (accuracy >= 0.40)
			return 'D';
		return 'F';
	}

	override public function create() {
		super.create();

		MasterAudio.playMenu(Paths.getPath('menus/resultScreen/$ratingPath/results-intro', 'music'), 0.6, 126);

		var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
		bg.scrollFactor.set();
		add(bg);

		var soundSystem:FunkinSprite = new FunkinSprite(-15, -200, true);
		soundSystem.frames = Paths.getPath('menus/resultScreen/sound-system', 'animated');
		soundSystem.antialiasing = SaveData.data.antialiasing;
		soundSystem.scrollFactor.set();
		soundSystem.addAnim('sound system', 'sound system', 24, false);
		soundSystem.playAnim('sound system');
		add(soundSystem);

		var blackTopBar:FlxSprite = new FlxSprite();
		blackTopBar.loadGraphic(createResultsBar());
		blackTopBar.antialiasing = SaveData.data.antialiasing;
		blackTopBar.scrollFactor.set();
		blackTopBar.y = -blackTopBar.height;
		FlxTween.tween(blackTopBar, {y: 0}, 7 / 24, {ease: FlxEase.quartOut, startDelay: 3 / 24});
		add(blackTopBar);

		results = new FunkinSprite(-95, 0, true);
		results.frames = Paths.getPath('menus/resultScreen/results', 'animated');
		results.antialiasing = SaveData.data.antialiasing;
		results.scrollFactor.set();
		results.addAnim('results', 'results', 24, false);
		results.playAnim('results');
		results.scale.set(0.9, 0.9);
		results.updateHitbox();
		add(results);

		rating = new FlxSprite(-400, 100);
		rating.loadGraphic(Paths.getPath('menus/resultScreen/ratings/' + ratingPath, 'image'));
		rating.antialiasing = SaveData.data.antialiasing;
		rating.scale.set(1.3, 1.3);
		rating.updateHitbox();
		rating.scrollFactor.set();
		add(rating);

		scorePopin = new FunkinSprite(-125, FlxG.height * 0.72, true);
		scorePopin.frames = Paths.getPath('menus/resultScreen/score-popin', 'animated');
		scorePopin.antialiasing = SaveData.data.antialiasing;
		scorePopin.scrollFactor.set();
		scorePopin.addAnim('tally score', 'tally score', 24, false);
		scorePopin.playAnim('tally score');
		scorePopin.scale.set(0.9, 0.9);
		scorePopin.updateHitbox();
		add(scorePopin);

		highscoreSprite = new FunkinSprite(0, FlxG.height * 0.75, true);

		@:privateAccess
		var highScore:Int = SaveScore.getScore(PlayState.SONG.songName, states.menus.FreeplayState.curDiff);

		newHighScore = playStateConfig.score > highScore;

		if (newHighScore) {
			highscoreSprite.frames = Paths.getPath('menus/resultScreen/highscoreNew', 'animated');
			highscoreSprite.antialiasing = SaveData.data.antialiasing;
			highscoreSprite.scrollFactor.set();
			highscoreSprite.addAnim('highscoreAnim', 'highscoreAnim', 24, false);
			highscoreSprite.playAnim('highscoreAnim');
			highscoreSprite.updateHitbox();
			add(highscoreSprite);
		}

		buildScoreDisplay();
		onScoreFinished();
	}

	function createResultsBar():BitmapData {
		final width:Int = Math.ceil(FlxG.width * 1.011);
		final mainBitmap = new BitmapData(width, Math.ceil(width / 8.7), true, 0xFF000000);
		final bitmap = new BitmapData(width, Math.ceil(width / 8.7), true, 0);
		final rect = mainBitmap.rect.clone();
		final matrix = new Matrix();

		matrix.rotate(-3.8 * Math.PI / 180);
		matrix.translate(-15, 0);
		rect.width -= 15;

		bitmap.draw(mainBitmap, matrix, rect, true);
		return bitmap;
	}

	var digitNames:Array<String> = ['ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE'];
	var scoreDigits:Array<FunkinSprite> = [];
	var digitCurrentNum:Array<Int> = [];
	var digitFinalNum:Array<Int> = [];
	var digitShuffling:Array<Bool> = [];
	var digitTweens:Array<flixel.tweens.FlxTween> = [];
	var digitTimers:Array<flixel.util.FlxTimer> = [];

	var tickSound:flixel.system.FlxSound;

	function buildScoreDisplay() {
		tickSound = FlxG.sound.load(Paths.getPath('menus/scrollMenu', 'sound'));

		for (i in 0...10) {
			var digit = new FunkinSprite(100 + i * 60, FlxG.height * 0.83, true);
			digit.frames = Paths.getPath('menus/resultScreen/score-digital-numbers', 'animated');
			digit.antialiasing = SaveData.data.antialiasing;
			digit.scrollFactor.set();
			digit.scale.set(0.9, 0.9);

			for (name in digitNames)
				digit.addAnim(name, '$name DIGITAL', 24, false);
			digit.addAnim('DISABLED', 'DISABLED', 24, false);
			digit.addAnim('GONE', 'GONE', 24, false);
			digit.playAnim('DISABLED');
			digit.updateHitbox();
			add(digit);

			scoreDigits.push(digit);
			digitCurrentNum.push(10);
			digitFinalNum.push(10);
			digitShuffling.push(false);
			digitTweens.push(null);
			digitTimers.push(null);
		}
	}

	function playDigitAnim(index:Int, num:Int) {
		var anim = num == 10 ? 'GONE' : num == -1 ? 'DISABLED' : digitNames[num];
		if (scoreDigits[index].animation.curAnim?.name != anim) {
			scoreDigits[index].playAnim(anim);
			scoreDigits[index].updateHitbox();
			scoreDigits[index].centerOffsets(false);

			digitCurrentNum[index] = num;
			if (num >= 0 && num <= 9) {
				tickSound.stop();
				tickSound.play();
			}
		}
	}

	function animateScore(score:Int) {
		var scoreStr = Std.string(score);
		var finals:Array<Int> = [];
		for (i in 0...(10 - scoreStr.length))
			finals.push(-1);
		for (ch in scoreStr.split(''))
			finals.push(Std.parseInt(ch));

		for (i in 0...10) {
			digitFinalNum[i] = finals[i];

			if (finals[i] == -1) {
				playDigitAnim(i, -1);
				continue;
			}

			var delay = (10 - 1 - i) * 0.08;

			var idx = i;
			new FlxTimer().start(delay, function(_) {
				startDigitShuffle(idx, finals[idx]);
			});
		}
	}

	function startDigitShuffle(index:Int, finalNum:Int) {
		digitShuffling[index] = true;

		var shuffleInterval:Float = 1 / 24;
		var shuffleDuration:Float = 41 / 24;
		var loops:Int = Std.int(shuffleDuration / shuffleInterval);
		var currentNum = 0;

		playDigitAnim(index, currentNum);

		if (digitTimers[index] != null)
			digitTimers[index].cancel();
		digitTimers[index] = new FlxTimer().start(shuffleInterval, function(t:FlxTimer) {
			currentNum = (currentNum + 1) % 10;
			playDigitAnim(index, currentNum);

			if (t.loops > 0 && t.loopsLeft == 0) {
				finishDigitTween(index, currentNum, finalNum);
			}
		}, loops);
	}

	function finishDigitTween(index:Int, fromNum:Int, finalNum:Int) {
		if (digitTweens[index] != null)
			digitTweens[index].cancel();

		digitTweens[index] = FlxTween.num(fromNum, finalNum, 23 / 24, {
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				scoreDigits[index].animation.play(scoreDigits[index].animation.curAnim.name, true, false, 0);
			}
		}, function(x:Float) {
			var rounded = Math.floor(x);
			if (rounded != digitCurrentNum[index])
				playDigitAnim(index, rounded);
		});
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		if (Controls.ACCEPT) {
			acceptOption = true;

			FlxTween.num(1.0, 0.3, 1.5, {ease: FlxEase.quadIn}, function(p) {
				if (FlxG.sound.music != null)
					FlxG.sound.music.pitch = p;
			});
			FlxTween.num(FlxG.sound.music?.volume ?? 0.6, 0.0, 1.5, {ease: FlxEase.quadIn}, function(v) {
				if (FlxG.sound.music != null)
					FlxG.sound.music.volume = v;
			});

			new FlxTimer().start(1, function(_) {
				if (!PlayStateConfig.isStoryMode)
					MusicBeatState.switchState(() -> new states.menus.FreeplayState());
				else
					MusicBeatState.switchState(() -> new states.menus.StoryMenuState());
			});
		}
	}

	function onScoreFinished() {
		animateScore(playStateConfig.score);

		var totalDelay = (10 - 1) * 0.08 + (41 / 24) + (23 / 24) + 0.3;
		new FlxTimer().start(totalDelay, function(_) {
			MasterAudio.playMenu(Paths.getPath('menus/resultScreen/$ratingPath/results', 'music'), 0.6, 126);
			new FlxTimer().start(0.3, function(_) {
				FlxTween.tween(rating, {x: FlxG.width * 0.65}, 0.6, {ease: FlxEase.elasticInOut});
				new FlxTimer().start(0.4, function(_) {
					FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
					FlxG.camera.flash(0xFFFFFFFF, 0.4);
				});
			});
		});
	}
}

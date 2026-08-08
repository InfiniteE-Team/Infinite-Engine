package;

import game.PlayStateConfig;

class ResultScreen extends ScriptState {
	var results:FunkinSprite;
	var rating:FlxSprite;
	var highscore:FunkinSprite;
	var scorePopin:FunkinSprite;

	var newHighScore:Bool = true;

	var acceptOption:Bool = false;

	var ratingPath:String = 'SS';

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		MasterAudio.playMenu(Paths.getPath('menus/resultScreen/$ratingPath/results', 'music'), 0.6, 126);

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getPath('menus/menuBG', 'image'));
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

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
		rating.loadGraphic(Paths.getPath('menus/resultScreen/ratings/'+ratingPath, 'image'));
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

		highscore = new FunkinSprite(0, FlxG.height * 0.75, true);

		if (newHighScore) {
			highscore.frames = Paths.getPath('menus/resultScreen/highscoreNew', 'animated');
			highscore.antialiasing = SaveData.data.antialiasing;
			highscore.scrollFactor.set();
			highscore.addAnim('highscoreAnim', 'highscoreAnim', 24, false);
			highscore.playAnim('highscoreAnim');
			highscore.updateHitbox();
			add(highscore);
		}

		new FlxTimer().start(1, function(_) {
			FlxTween.tween(rating, {x: FlxG.width * 0.65}, 0.6, {ease: FlxEase.elasticInOut});
			new FlxTimer().start(0.4, function(_) {
				FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
				FlxG.camera.flash(0xFFFFFFFF, 0.4);
			});
		});
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		if (Controls.ACCEPT) {
			acceptOption = true;

			new FlxTimer().start(1, function() {
				FlxTween.tween(rating, {y: rating.y + 800}, 2);
				FlxTween.tween(scorePopin, {y: scorePopin.y + 800}, 2);
				FlxTween.tween(highscore, {y: highscore.y + 800}, 2);
				FlxTween.tween(results, {y: results.y + 800}, 2);
				if (!PlayStateConfig.isStoryMode)
					MusicBeatState.switchState(() -> new states.menus.FreeplayState());
				else
					ScriptClass.switchState('StoryMenuState');
			});
		}
	}
}

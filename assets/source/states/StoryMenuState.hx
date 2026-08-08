package;

import flixel.util.FlxStringUtil;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxTween.FlxTweenType;

class StoryMenuState extends ScriptState {
	var storyData:core.json.engine.WeekData;

	var scoreText:FlxText;

	var acceptOption:Bool = false;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		loadJson();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFDCC202);
		bg.screenCenter();
		add(bg);

		var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 70, 0xFF000000);
		add(black);

		var black2:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 275, 0xFF000000);
		black2.screenCenter();
		black2.y = FlxG.height / 2 + 125;
		add(black2);

		scoreText = new FlxText(10, 17, FlxG.width, "LEVEL SCORE: 0");
		scoreText.setFormat(Paths.getPath('vcr.ttf', 'font'), 40, 0xFFFFFFFF, "left");
		scoreText.antialiasing = SaveData.data.antialiasing;
		scoreText.scrollFactor.set(0, 0);
		add(scoreText);

		var description:FlxText = new FlxText(-10, 17, FlxG.width, "SCOOBY DOO PA PA");
		description.setFormat(Paths.getPath('vcr.ttf', 'font'), 40, 0xFF878787, "right");
		description.antialiasing = SaveData.data.antialiasing;
		description.scrollFactor.set(0, 0);
		add(description);

		var tracks:FlxText = new FlxText(-470, FlxG.height * 0.725, FlxG.width, "TRACKS");
		tracks.setFormat(Paths.getPath('vcr.ttf', 'font'), 30, 0xFFD93939, "center");
		tracks.antialiasing = SaveData.data.antialiasing;
		tracks.scrollFactor.set(0, 0);
		add(tracks);

		if (storyData != null) {
			var noExists = new FlxText(0, FlxG.height / 2 - 35, FlxG.width, "There are no songs! - Create your music list in 'songs/listSong.json'");
			noExists.setFormat(Paths.getPath('5by7_b.ttf', 'font'), 24, 0xFFFFB2B2, "center");
			noExists.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			noExists.antialiasing = SaveData.data.antialiasing;
			noExists.alpha = 0;
			noExists.scrollFactor.set(0, 0);
			add(noExists);

			FlxTween.tween(noExists, {alpha: 1}, 1, {type: FlxTweenType.PINGPONG});
		} else {}
	}

	function loadJson() {
		var resolved = Paths.getPath('data/weeks');
		if (resolved == null || !FileSystem.exists(resolved))
			return;
		for (file in FileSystem.readDirectory(resolved))
			storyData = FormatJson.readJson(Paths.getPath('data/weeks/$file', 'json'));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		if (Controls.BACK) {
			acceptOption = true;
			ScriptClass.switchState('MainMenuState');
		}
	}
}
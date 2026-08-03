package states.substates.menus;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class PauseMenuSubstate extends states.substates.MusicBeatSubstate {
	var bg:FlxSprite;

	var text:FlxText;

	var options:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to Menu'];

	var tips:Array<String> = ["wey tienes que darle a las flechitas no seas bobis"];

	var curSelect:Int = 0;

	var texts:Array<FlxText> = [];

	var infoSongs:Array<FlxText> = [];

	public var pauseMenuMusic:FlxSound;

	static var _cachedPauseMusic:FlxSound;

	var nameSong:FlxText;
	var difficulty:FlxText;
	var blueBalled:FlxText;

	override public function create() {
		super.create();

		#if HSCRIPT_ALLOWED
		initScript();
		script.executeAll();
		script.call("onCreate", []);
		#end

		if (_cachedPauseMusic == null) {
			pauseMenuMusic = new FlxSound();
			pauseMenuMusic.load(Paths.getPath('menus/pauseInfinite', "music"), false);
			pauseMenuMusic.looped = true;
			FlxG.sound.list.add(pauseMenuMusic);
			_cachedPauseMusic = pauseMenuMusic;
		} else {
			pauseMenuMusic = _cachedPauseMusic;
		}

		pauseMenuMusic.volume = 0.7;
		pauseMenuMusic.play();

		this.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		bg = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
		bg.antialiasing = SaveData.data.antialiasing;
		bg.alpha = 0.6;
		bg.scrollFactor.set(0, 0);
		bg.screenCenter();
		add(bg);

		for (i in 0...options.length) {
			text = new FlxText(100, 100 + (i * 60), FlxG.width, options[i]);
			text.setFormat(Paths.getPath('Funkin.otf', 'font'), 34, 0xFFFFFFFF, "left");
			text.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			text.antialiasing = SaveData.data.antialiasing;
			text.scrollFactor.set(0, 0);
			texts.push(text);
			add(text);
		}

		var textInfo:Array<String> = [
			game.PlayState.instance.curSong,
			'Difficulty: ${core.rhythm.DiffsUtils.diffCurrent.toUpperCase()}',
			'Blue Balled: ${game.PlayStateConfig.blueBalled}'
		];

		for (i in 0...textInfo.length) {
			var infoSong = new FlxText(0, 0 + (i * 38), FlxG.width - 20, textInfo[i]);
			infoSong.setFormat(Paths.getPath('Funkin.otf', 'font'), 32, 0xFFFFFFFF, "right");
			infoSong.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			infoSong.antialiasing = SaveData.data.antialiasing;
			infoSong.scrollFactor.set(0, 0);
			infoSong.alpha = 0;
			infoSongs.push(infoSong);
			add(infoSong);
		}

		nameSong = infoSongs[0];
		difficulty = infoSongs[1];
		blueBalled = infoSongs[2];

		FlxTween.tween(nameSong, {alpha: 1, y: nameSong.y + 20}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(difficulty, {alpha: 1, y: difficulty.y + 20}, 0.7, {ease: FlxEase.circOut});
		FlxTween.tween(blueBalled, {alpha: 1, y: blueBalled.y + 20}, 0.9, {ease: FlxEase.circOut});

		var tipText = new FlxText(0, 0, FlxG.width, tips[Std.random(tips.length)]);
		tipText.setFormat(Paths.getPath('Funkin.otf', 'font'), 24, 0xFFFFFFFF, "center");
		tipText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		tipText.antialiasing = SaveData.data.antialiasing;
		tipText.alpha = 0;
		tipText.scrollFactor.set(0, 0);
		tipText.y = FlxG.height - tipText.height - 40;
		add(tipText);

		FlxTween.tween(tipText, {alpha: 1, y: tipText.y + 20}, 1.2, {ease: FlxEase.circOut});

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end

		changeCur(0);
	}

	override public function update(elapsed:Float) {
		#if HSCRIPT_ALLOWED
		script.call("onUpdate", [elapsed]);
		#end

		if (Controls.BACK) {
			resumeFunction();
			#if HSCRIPT_ALLOWED script.call("ExitMenu", []); #end
		}

		if (options.length > 0) {
			if (Controls.UI_UP)
				changeCur(-1);
			else if (Controls.UI_DOWN)
				changeCur(1);
		}

		if (Controls.ACCEPT) {
			switch (options[curSelect]) {
				case "Resume":
					resumeFunction();
					close();
				case "Restart Song":
					resumeFunction();
					if (game.PlayState.instance != null)
						game.PlayState.instance.rewindSong();
					close();
				case "Change Difficulty":
					trace('wip');
				case "Options":
					openSubState(new states.substates.menus.OptionsMenuSubstate());
				case "Exit to Menu":
					resumeFunction();
					game.PlayStateConfig.blueBalled = 0;
					#if HSCRIPT_ALLOWED
					script.call("ExitMenu", []);
					#end
			}
		}

		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		script.call("postUpdate", [elapsed]);
		#end
	}

	function resumeFunction() {
		if (game.PlayState.instance != null) {
			game.PlayState.instance.paused = false;
			game.PlayState.instance.countDown.resume();
		}
		if (pauseMenuMusic != null) {
			pauseMenuMusic.pause();
		}
		#if HSCRIPT_ALLOWED
		script.call("onResumePause", []);
		#end
	}

	public function changeCur(change:Int) {
		curSelect += change;

		if (change != 0)
			FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'), 0.7);

		if (curSelect >= options.length)
			curSelect = 0;
		if (curSelect < 0)
			curSelect = options.length - 1;

		for (i in 0...texts.length) {
			texts[i].alpha = (i == curSelect) ? 1.0 : 0.4;
		}
	}

	override function destroy() {
		for (t in texts)
			t.destroy();
		texts = null;
		text = null;

		for (info in infoSongs)
			info.destroy();
		infoSongs = null;
		

		if (pauseMenuMusic != null) {
			pauseMenuMusic.stop();
			FlxG.sound.list.remove(pauseMenuMusic, true);
			pauseMenuMusic.destroy();
			pauseMenuMusic = null;
			_cachedPauseMusic = null;
		}

		super.destroy();
	}
}

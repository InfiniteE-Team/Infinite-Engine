package states.substates;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;

class PauseMenuSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;

	var text:FlxText;

	var options:Array<String> = ['Resume', 'Restart Song', 'Options', 'Exit to Menu'];

	var curSelect:Int = 0;

	var texts:Array<FlxText> = [];

	public var pauseMenuMusic:FlxSound;

	static var _cachedPauseMusic:FlxSound;

	override public function create() {
		super.create();

		#if HSCRIPT_ALLOWED
		initScript();
		script.executeAll();
		script.call("onCreate", []);
		#end

		if (_cachedPauseMusic == null) {
			pauseMenuMusic = new FlxSound();
			pauseMenuMusic.loadEmbedded(Paths.getPath('pauseInfinite', "music"), true, false, null);
			FlxG.sound.list.add(pauseMenuMusic);
			_cachedPauseMusic = pauseMenuMusic;
		} else {
			pauseMenuMusic = _cachedPauseMusic;
		}

		pauseMenuMusic.volume = 0.7;
		pauseMenuMusic.play();

		this.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		bg = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
		bg.antialiasing = true;
		bg.alpha = 0.6;
		bg.scrollFactor.set(0, 0);
		bg.screenCenter();
		add(bg);

		for (i in 0...options.length) {
			text = new FlxText(100, 100 + (i * 60), FlxG.width, options[i]);
			text.setFormat(Paths.getPath('Funkin.otf', 'font'), 34, 0xFFFFFFFF, "left");
			text.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			text.antialiasing = true;
			text.scrollFactor.set(0, 0);
			texts.push(text);
			add(text);
		}

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end
	}

	override public function update(elapsed:Float) {
		#if HSCRIPT_ALLOWED
		script.call("onUpdate", [elapsed]);
		#end

		changeCur();

		if (input.control.justPressedAction("uiKeys", 'accept')) {
			switch (options[curSelect]) {
				case "Resume":
					resumeFunction();
					close();
				case "Restart Song":
					resumeFunction();
					if (game.PlayState.instance != null)
						game.PlayState.instance.rewindSong();
					close();
				case "Options":
					openSubState(new states.substates.OptionsMenuSubstate());
				case "Exit to Menu":
					resumeFunction();
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
			game.PlayState.instance.windowMod.resumeWindow();
		}
		if (pauseMenuMusic != null) {
			pauseMenuMusic.pause();
		}
		#if HSCRIPT_ALLOWED
		script.call("onResumePause", []);
		#end
	}

	public function changeCur() {
		if (input.control.justPressedAction("uiKeys", "up") && options.length > 0) {
			FlxG.sound.play(Paths.getPath('scrollMenu', 'sound'), 0.7);
			curSelect += 1;
		} else if (input.control.justPressedAction("uiKeys", "down") && options.length > 0) {
			FlxG.sound.play(Paths.getPath('scrollMenu', 'sound'), 0.7);
			curSelect -= 1;
		}

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

		if (pauseMenuMusic != null) {
			pauseMenuMusic.stop();
		}

		super.destroy();
	}
}

package;

import core.EngineData;
import states.substates.menus.OptionsMenuSubstate;
import flixel.text.FlxTextBorderStyle;

class MainMenuState extends ScriptState {
	var options:Array<FlxSprite> = [];
	var menuOptions:Array<String> = ['storymode', 'freeplay', 'credits', 'options'];
	var curSelected:Int = 0;

	var acceptOption:Bool = false;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		MasterAudio.playMenu(Paths.getPath('menus/freakyMenu/freakyMenu', 'music'), 0.6, 102);

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.getPath('menus/menuBG', 'image'));
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		for (i in 0...menuOptions.length) {
			var option:FlxSprite = new FlxSprite(0, 100 + (i * 150));
			option.frames = Paths.getPath('menus/mainmenu/' + menuOptions[i], 'animated');
			option.animation.addByPrefix('idle', menuOptions[i] + ' idle', 24, true);
			option.animation.addByPrefix('selected', menuOptions[i] + ' selected', 24, true);
			option.antialiasing = SaveData.data.antialiasing;
			option.ID = i;
			option.animation.play('idle');
			option.x = (FlxG.width - option.width) / 2; // centre
			option.updateHitbox();
			options.push(option);
			add(option);
		}

		var game:FlxText = new FlxText(FlxG.width * 0.01, FlxG.height * 0.95, FlxG.width, 'Infinite Engine v' + EngineData.version);
		game.setFormat(Paths.getPath('Funkin.otf', 'font'), 24, 0xFFFFFFFF, "left");
		game.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		game.antialiasing = SaveData.data.antialiasing;
		game.scrollFactor.set(0, 0);
		add(game);

		change(0);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		var upP = Controls.UI_UP;
		var downP = Controls.UI_DOWN;
		var accept = Controls.ACCEPT;

		if (downP)
			change(1);
		if (upP)
			change(-1);

		if (FlxG.keys.justPressed.TAB)
			ScriptClass.openSubstate('ModsSubstate');

		if (accept) {
			FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
			FlxG.camera.flash(0xFFFFFFFF, 0.4);
			new FlxTimer().start(1, function() {
				switch (menuOptions[curSelected]) {
					case 'storymode':
						acceptOption = true;
						trace("In Story Mode");
					case 'freeplay':
						acceptOption = true;
						MusicBeatState.switchState(() -> new states.menus.FreeplayState());
					case 'credits':
						acceptOption = true;
						trace("In Credits");
					case 'options':
						openSubState(new OptionsMenuSubstate());
				}
			});
		}

		if (Controls.BACK) {
			acceptOption = true;
			ScriptClass.switchState('TitleState');
		}
	}

	public function change(changeAmount:Int = 0):Void {
		curSelected += changeAmount;

		if (curSelected < 0)
			curSelected = menuOptions.length - 1;
		if (curSelected >= menuOptions.length)
			curSelected = 0;

		if (changeAmount != 0)
			FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));

		for (i in 0...options.length) {
			var item:FlxSprite = options[i];

			if (i == curSelected) {
				item.animation.play('selected');
				item.centerOffsets();
			} else {
				item.animation.play('idle');
				item.centerOffsets();
			}

			item.x = (FlxG.width - item.width) / 2; // centre
		}
	}
}

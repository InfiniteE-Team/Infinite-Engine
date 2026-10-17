package modding.editors;

import flixel.text.FlxText;

class DebugMenu extends MusicBeatState {
	var text:FlxText;
	var options:Array<FlxText> = [];
	var curOption:Int = 0;
	var optionsText:Array<String> = ['Character Editor', 'Gameplay Editor', 'Stage Editor'];
	var isAccept:Bool = false;

	override public function create() {
		super.create();

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/artistic-expression/artistic-expression', 'music'), 0.6, 137);

		final bg:flixel.FlxSprite = new flixel.FlxSprite().loadGraphic(Paths.getPath('menus/menuBG2', 'image'));
		bg.antialiasing = SaveData.data.antialiasing;
		bg.screenCenter();
		add(bg);

		for (i in 0...optionsText.length) {
			var option = new FlxText(0, 120 + i * 70, FlxG.width, optionsText[i]);
			option.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFFFFF, 'center');
			option.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			add(option);
			options.push(option);
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (isAccept)
			return;
		
		if (Controls.UI_UP) {
			curOption = (curOption - 1 + options.length) % options.length;
		} else if (Controls.UI_DOWN) {
			curOption = (curOption + 1) % options.length;
		}

		for (i in 0...options.length) {
			options[i].color = (i == curOption) ? 0xFFFFFF00 : 0xFFFFFFFF;
		}

		if (Controls.ACCEPT) {
			isAccept = true;
			switch (curOption) {
				case 0:
					MusicBeatState.switchState(() -> new CharacterEditor('bf'));
				case 1:
					Console.log("Gameplay Editor for now, it only opens during gameplay..");

				// MusicBeatState.switchState(new GameplayEditor());
				case 2:
					Console.log("Stage Editor is not implemented yet.");
					// MusicBeatState.switchState(new StageEditor());
			}
		}

		if (Controls.BACK) {
			isAccept = true;
			modding.scripting.types.ScriptClass.switchState('MainMenuState');
		}
	}
}

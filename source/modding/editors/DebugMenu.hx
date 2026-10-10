package modding.editors;

import flixel.text.FlxText;

class DebugMenu extends MusicBeatState {
	var text:FlxText;
	var options:Array<FlxText> = [];
	var curOption:Int = 0;
	var optionsText:Array<String> = ['Character Editor', 'Gameplay Editor', 'Stage Editor'];

	override public function create() {
		super.create();

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/artistic-expression/artistic-expression', 'music'), 0.6, 137);

		for (i in 0...optionsText.length) {
			var option = new FlxText(0, 0, FlxG.width, optionsText[i]);
			option.setFormat(null, 16, 0xFFFFFFFF, 'center');
			option.y = 100 + i * 30;
			add(option);
			options.push(option);
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.UI_UP) {
			curOption = (curOption - 1 + options.length) % options.length;
		} else if (Controls.UI_DOWN) {
			curOption = (curOption + 1) % options.length;
		}

		for (i in 0...options.length) {
			options[i].color = (i == curOption) ? 0xFFFFFF00 : 0xFFFFFFFF;
		}

		if (Controls.ACCEPT) {
			switch (curOption) {
				case 0:
					MusicBeatState.switchState(() -> new CharacterEditor('bf'));
				case 1:
                    Console.log("Gameplay Editor for now, it only opens during gameplay..");

					//MusicBeatState.switchState(new GameplayEditor());
				case 2:
                    Console.log("Stage Editor is not implemented yet.");
					//MusicBeatState.switchState(new StageEditor());
			}
		}

		if (Controls.BACK)
			modding.scripting.types.ScriptClass.switchState('MainMenuState');
	}
}

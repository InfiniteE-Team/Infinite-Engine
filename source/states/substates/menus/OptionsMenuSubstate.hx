package states.substates.menus;

import flixel.FlxSprite;
import flixel.text.FlxText;
import core.json.engine.OptionData;

class OptionsMenuSubstate extends states.substates.MusicBeatSubstate {
	var categoryTexts:Array<FlxText> = [];
	var categories:Array<String> = ['Gameplay', 'Keybinds', 'Graphics'];
	var curCategory:Int = 0;

	var categoryOptions:Map<String, Array<OptionData>> = [
		'Gameplay' => [
			{
				name: 'Downscroll',
				description: 'Reverse the direction of the notes downwards.',
				saveField: 'downscroll',
				type: CHECKBOX
			},
			{
				name: 'Middlescroll',
				description: 'Center your notes on the screen.',
				saveField: 'middlescroll',
				type: CHECKBOX
			},
			{
				name: 'Ghost Tapping',
				description: 'Avoid penalties when pressing keys without notes.',
				saveField: 'ghosttaping',
				type: CHECKBOX
			}
		],
		'Graphics' => [
			{
				name: 'Framerate',
				description: 'Adjust the frames per second limit.',
				saveField: 'framerate',
				type: NUMBER(30, 240, 10)
			},
			{
				name: 'Antialiasing',
				description: 'It softens the edges of the images.',
				saveField: 'antialiasing',
				type: CHECKBOX
			},
			{
				name: 'Shaders',
				description: 'Enables advanced visual effects.',
				saveField: 'shaders',
				type: CHECKBOX
			}
		],
		'Keybinds' => []
	];

	var curSelectedOption:Int = 0;
	var itemTexts:Array<FlxText> = [];
	var valueTexts:Array<FlxText> = [];
	var descText:FlxText;

	var isCategory:Bool = true;

	override public function create() {
		super.create();

		this.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF050505);
		bg.alpha = 0.8;
		add(bg);

		var options:FlxText = new FlxText(0, 20, bg.width - 40, 'OPTIONS');
		options.setFormat(Paths.getPath('Funkin.otf', 'font'), 40, 0xFFFFFFFF, "center");
		options.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		options.antialiasing = SaveData.data.antialiasing;
		options.scrollFactor.set(0, 0);
		add(options);

		for (i in 0...categories.length) {
			var text:FlxText = new FlxText(50, 100 + (i * 50), 0, categories[i]);
			text.setFormat(Paths.getPath('Funkin.otf', 'font'), 34, 0xFFFFFFFF, "left");
			text.ID = i;
			text.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			text.antialiasing = SaveData.data.antialiasing;
			text.scrollFactor.set(0, 0);
			categoryTexts.push(text);
			add(text);
		}

		descText = new FlxText(0, bg.y + bg.height - 50, bg.width - 40, "");
		descText.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFFFFFF00, "center");
		descText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1.5, 1);
		add(descText);

		changeCategory(0);
		updateVisualFocus();
	}

	function changeCategory(change:Int = 0) {
		curCategory = (curCategory + change + categories.length) % categories.length;

		for (i in 0...categoryTexts.length) {
			categoryTexts[i].color = (i == curCategory) ? 0xFFFFFF00 : 0xFFFFFFFF;
			categoryTexts[i].alpha = (i == curCategory) ? 1.0 : 0.6;
		}

		curSelectedOption = 0;
		reloadOptions();
	}

	function reloadOptions() {
		for (txt in itemTexts)
			txt.destroy();
		for (val in valueTexts)
			val.destroy();
		itemTexts = [];
		valueTexts = [];

		var currentList = categoryOptions.get(categories[curCategory]);
		if (currentList == null)
			return;

		for (i in 0...currentList.length) {
			var opt = currentList[i];

			var optText:FlxText = new FlxText(300, 100 + (i * 50), 0, opt.name);
			optText.setFormat(Paths.getPath('Funkin.otf', 'font'), 26, 0xFFFFFFFF, "left");
			optText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			itemTexts.push(optText);
			add(optText);

			var rawValue = Reflect.field(SaveData.data, opt.saveField);
			var valueStr:String = Std.string(rawValue);

			var valText:FlxText = new FlxText(FlxG.width / 2 + 150, 100 + (i * 50), 0, valueStr);
			valText.setFormat(Paths.getPath('Funkin.otf', 'font'), 26, 0xFFFFFFFF, "right");
			valText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			valueTexts.push(valText);
			add(valText);
		}

		updateSelection(0);
	}

	function updateSelection(change:Int = 0) {
		var currentList = categoryOptions.get(categories[curCategory]);

		FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));
		if (currentList == null || currentList.length == 0) {
			descText.text = "Presiona ENTER para configurar controles.";
			return;
		}

		curSelectedOption = (curSelectedOption + change + currentList.length) % currentList.length;

		for (i in 0...itemTexts.length) {
			var isSelected = (i == curSelectedOption);
			if (!isCategory) {
				itemTexts[i].color = isSelected ? 0xFFFFFF00 : 0xFFFFFFFF;
				valueTexts[i].color = isSelected ? 0xFFFFFF00 : 0xFFFFFFFF;
			}
		}

		descText.text = currentList[curSelectedOption].description;
	}

	function updateVisualFocus() {
		if (isCategory) {
			for (i in 0...categoryTexts.length) {
				if (i == curCategory) {
					categoryTexts[i].color = 0xFFFFFF00;
				} else {
					categoryTexts[i].color = 0xFFFFFFFF;
				}
			}

			if (itemTexts != null && itemTexts.length > 0 && curSelectedOption < itemTexts.length) {
				if (itemTexts[curSelectedOption] != null) {
					itemTexts[curSelectedOption].color = 0xFFFFFFFF;
					itemTexts[curSelectedOption].alpha = 0.6;
				}
				if (valueTexts != null && valueTexts[curSelectedOption] != null) {
					valueTexts[curSelectedOption].color = 0xFFFFFFFF;
					valueTexts[curSelectedOption].alpha = 0.6;
				}
			}
		} else {
			if (categoryTexts != null && categoryTexts.length > 0 && curCategory < categoryTexts.length) {
				if (categoryTexts[curCategory] != null) {
					categoryTexts[curCategory].color = 0xFFFFFFFF;
					categoryTexts[curCategory].alpha = 0.6;
				}
			}

			for (i in 0...itemTexts.length) {
				if (i == curSelectedOption) {
					itemTexts[i].color = valueTexts[i].color = 0xFFFFFF00;
				} else {
					itemTexts[i].color = valueTexts[i].color = 0xFFFFFFFF;
				}
			}
		}
	}

	function changeOptionValue(direction:Int) {
		var currentList = categoryOptions.get(categories[curCategory]);
		if (currentList == null || currentList.length == 0)
			return;

		FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));

		var opt = currentList[curSelectedOption];
		var currentValue:Dynamic = Reflect.field(SaveData.data, opt.saveField);

		switch (opt.type) {
			case CHECKBOX:
				var newValue:Bool = !currentValue;
				Reflect.setField(SaveData.data, opt.saveField, newValue);

				if (opt.saveField == 'antialiasing' && !currentValue) {
					FlxSprite.defaultAntialiasing = false;
				}
			case NUMBER(min, max, step):
				var newValue:Float = currentValue + (direction * step);
				if (newValue < min)
					newValue = min;
				if (newValue > max)
					newValue = max;
				Reflect.setField(SaveData.data, opt.saveField, Math.round(newValue));

				if (opt.saveField == 'framerate') {
					FlxG.drawFramerate = Math.round(newValue);
					FlxG.updateFramerate = Math.round(newValue);
				}
		}

		SaveData.flush();

		valueTexts[curSelectedOption].text = Std.string(Reflect.field(SaveData.data, opt.saveField));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var currentList = categoryOptions.get(categories[curCategory]);
		var hasOptions = (currentList != null && currentList.length > 0);

		if (Controls.UI_LEFT) {
			if (!isCategory && hasOptions && currentList[curSelectedOption].type != CHECKBOX) {
				updateVisualFocus();
				changeOptionValue(-1);
			}
		}

		if (Controls.UI_RIGHT) {
			if (!isCategory && hasOptions && currentList[curSelectedOption].type != CHECKBOX) {
				updateVisualFocus();
				changeOptionValue(1);
			}
		}

		if (Controls.UI_UP) {
			if (!isCategory && hasOptions) {
				updateSelection(-1);
			} else {
				updateVisualFocus();
				changeCategory(-1);
			}
		}

		if (Controls.UI_DOWN) {
			if (!isCategory && hasOptions) {
				updateSelection(1);
			} else {
				updateVisualFocus();
				changeCategory(1);
			}
		}

		if (Controls.ACCEPT) {
			if (isCategory && hasOptions) {
				FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
				isCategory = false;
				updateVisualFocus();
			} else if (!isCategory && hasOptions && currentList[curSelectedOption].type == CHECKBOX) {
				updateVisualFocus();
				changeOptionValue(1);
			}
		}

		if (Controls.BACK) {
			if (!isCategory) {
				isCategory = true;
				updateVisualFocus();
				FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
			} else {
				close();
				if (game.PlayStateConfig.isPlaying)
					MusicBeatState.resetState();
			}
		}
	}

	override function destroy() {
		super.destroy();
	}
}

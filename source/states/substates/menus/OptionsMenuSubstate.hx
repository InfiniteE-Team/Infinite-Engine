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
				type: NUMBER(30, 240, 5)
			},/*
			{
				name: 'FPS Visible',
				description: 'Display the current frames per second.',
				saveField: 'fpsVisible',
				type: CHECKBOX
			},*/
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

	// Character preview
	var character:game.objects.sprites.Character;

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

		try {
			character = new game.objects.sprites.Character('bf', 'bf', 500, 150);
		} catch (e:Dynamic) {
			Trace.traceOnce('Warning: The character could not be loaded in the secondary menu. Reason: $e\n${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}');
			character = null;
		}

		if (character != null) {
			character.visible = false;
			character.setPosition(FlxG.width - 450, FlxG.height - 500);

			if (character.layers != null) {
				for (layer in character.layers) {
					if (layer != null) {
						layer.visible = false;
						add(layer);
					}
				}
			}
			add(character);
		}

		if (character != null && (character.existsAnim('idle') || character.existsAnim('danceLeft'))) {
			character.dance();
		}

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
			descText.text = "Press ENTER to configure controls.";
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
		updateCharacterVisibility();
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

		updateCharacterVisibility();
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

				if (opt.saveField == 'antialiasing') {
					FlxSprite.defaultAntialiasing = newValue;
					updateAntialiasingLive(newValue);
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

	function updateAntialiasingLive(enabled:Bool) {
		if (character != null) {
			character.antialiasing = enabled;
			if (character.layers != null) {
				for (layer in character.layers) {
					if (layer != null) {
						layer.antialiasing = enabled;
					}
				}
			}
		}

		for (txt in categoryTexts) {
			if (txt != null)
				txt.antialiasing = enabled;
		}
		for (txt in itemTexts) {
			if (txt != null)
				txt.antialiasing = enabled;
		}
		for (txt in valueTexts) {
			if (txt != null)
				txt.antialiasing = enabled;
		}
		if (descText != null)
			descText.antialiasing = enabled;
	}

	function updateCharacterVisibility() {
		if (character == null)
			return;

		var showChar:Bool = false;

		if (!isCategory) {
			var currentList = categoryOptions.get(categories[curCategory]);
			if (currentList != null && currentList.length > 0 && curSelectedOption < currentList.length) {
				var optName = currentList[curSelectedOption].name;
				if (optName == 'Shaders' || optName == 'Antialiasing') {
					showChar = true;
				}
			}
		}

		character.visible = showChar;
		if (character.layers != null) {
			for (layer in character.layers) {
				if (layer != null) {
					layer.visible = showChar;
				}
			}
		}
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

	override function beatHit(beat:Float) {
		super.beatHit(beat);

		if (character != null && character.visible) {
			character.dance();
		}
	}

	override function destroy() {
		if (character != null) {
			if (character.layers != null) {
				for (layer in character.layers) {
					if (layer != null) {
						remove(layer);
						layer.destroy();
					}
				}
			}
			remove(character);
			character.destroy();
			character = null;
		}

		super.destroy();

		categoryTexts = null;
		itemTexts = null;
		valueTexts = null;
		descText = null;
	}
}

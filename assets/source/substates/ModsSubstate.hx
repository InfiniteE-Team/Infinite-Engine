package;

import core.api.WindowAPI;
import core.assets.Library;
import flixel.text.FlxTextBorderStyle;
import modding.mods.ModsRegistry;

class ModsSubstate extends ScriptSubstate {
	var curSelected:Int = 0;
	var listMods:Array<FlxText> = [];
	var acceptOption:Bool = false;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		Library.reloadMods();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF050505);
		bg.alpha = 0.6;
		add(bg);

		if (ModsRegistry.mods.length == 0) {
			var noModsText:FlxText = new FlxText(0, FlxG.height * 0.45, FlxG.width, "NO MODS FOUND");
			noModsText.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFFFFF, "center");
			noModsText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 3, 1);
			noModsText.antialiasing = SaveData.data.antialiasing;
			noModsText.scrollFactor.set(0, 0);
			add(noModsText);
			return;
		}

		for (i in 0...ModsRegistry.mods.length) {
			var mod:FlxText = new FlxText(100, 100 + (i * 60), FlxG.width, ModsRegistry.mods[i]);
			mod.setFormat(Paths.getPath('Funkin.otf', 'font'), 32, 0xFFFFFFFF, "left");
			mod.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
			mod.antialiasing = SaveData.data.antialiasing;
			mod.ID = i;
			mod.scrollFactor.set(0, 0);
			listMods.push(mod);
			add(mod);
		}

		changeSelection(0);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		if (ModsRegistry.mods.length > 0) {
			if (Controls.UI_UP)
				changeSelection(-1);

			if (Controls.UI_DOWN)
				changeSelection(1);
		}

		if (Controls.ACCEPT) {
			if (ModsRegistry.currentMod == ModsRegistry.mods[curSelected])
				return;

			acceptOption = true;
			ModsRegistry.onMod = true;
			ModsRegistry.currentMod = ModsRegistry.mods[curSelected];

			SaveData.data.currentMod = ModsRegistry.currentMod;
			SaveData.data.onMod = true;
			SaveData.flush();

			trace("Mod actual: " + ModsRegistry.currentMod);

			FlxTimer.wait(0.1, () -> {
				@:privateAccess
				Paths.clearCache();
				FlxG.bitmap.clearCache();
				WindowAPI.restartApp();
			});
		}

		if (Controls.BACK)
			close();
	}

	function changeSelection(change:Int = 0):Void {
		curSelected += change;

		if (curSelected < 0)
			curSelected = ModsRegistry.mods.length - 1;
		if (curSelected >= ModsRegistry.mods.length)
			curSelected = 0;

		for (item in listMods) {
			if (item.ID == curSelected) {
				item.alpha = 1.0;
				item.color = 0xFFFFFF00;
			} else {
				item.alpha = 0.6;
				item.color = 0xFFFFFFFF;
			}
		}
	}
}

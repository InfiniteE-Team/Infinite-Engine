package;

import core.api.WindowAPI;
import core.assets.Library;
import flixel.text.FlxTextBorderStyle;
import modding.mods.ModsRegistry;

class ModsState extends ScriptState {
	var curSelected:Int = 0;
	var listMods:Array<FlxText> = [];
	var acceptOption:Bool = false;

	var boyfriend:FunkinSprite;
	var gf:FunkinSprite;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		Library.reloadMods();

		var bg:FunkinSprite = new FunkinSprite(0, 0, true).loadGraphic(Paths.getPath('menus/mods/bg', 'image'));
		bg.scale.set(0.665, 0.665);
		bg.updateHitbox();
		bg.antialiasing = SaveData.data.antialiasing;
		bg.screenCenter();
		add(bg);

		var bgwires:FunkinSprite = new FunkinSprite(1030, 260, true).loadGraphic(Paths.getPath('menus/mods/bgwires', 'image'));
		bgwires.scale.set(0.72, 0.72);
		bgwires.updateHitbox();
		bgwires.antialiasing = SaveData.data.antialiasing;
		add(bgwires);

		var carbattery:FunkinSprite = new FunkinSprite(970, 100, true);
		carbattery.frames = Paths.getPath('menus/mods/carbattery', 'animated');
		carbattery.addAnim('idle', 'idle', 24, true);
		carbattery.antialiasing = SaveData.data.antialiasing;
		carbattery.playAnim('idle');
		carbattery.scale.set(0.72, 0.72);
		carbattery.updateHitbox();
		add(carbattery);

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

		var toptext:FunkinSprite = new FunkinSprite(325, 32, true).loadGraphic(Paths.getPath('menus/mods/top-text', 'image'));
		toptext.antialiasing = SaveData.data.antialiasing;
		toptext.scale.set(0.7, 0.7);
		toptext.updateHitbox();
		add(toptext);

		gf = new FunkinSprite(800, 240, true);
		gf.frames = Paths.getPath('menus/mods/characters/gf', 'animated');
		gf.addAnim('idle', 'gf idle', 24, true);
		gf.addAnim('press', 'electrocuted', 24, true);
		gf.antialiasing = SaveData.data.antialiasing;
		gf.playAnim('idle');
		gf.scale.set(0.72, 0.72);
		gf.updateHitbox();
		add(gf);

		boyfriend = new FunkinSprite(950, 240, true);
		boyfriend.frames = Paths.getPath('menus/mods/characters/bf', 'animated');
		boyfriend.addAnim('idle', 'bf idle', 24, true);
		boyfriend.addAnim('press', 'electrocuted', 24, true);
		boyfriend.antialiasing = SaveData.data.antialiasing;
		boyfriend.playAnim('idle');
		boyfriend.scale.set(0.72, 0.72);
		boyfriend.updateHitbox();
		add(boyfriend);

		var foregrounds1:FunkinSprite = new FunkinSprite(687, 50, true);
		foregrounds1.frames = Paths.getPath('menus/mods/foreground-wires', 'animated');
		foregrounds1.addAnim('idle', 'idle', 24, true);
		foregrounds1.antialiasing = SaveData.data.antialiasing;
		foregrounds1.playAnim('idle');
		foregrounds1.scale.set(0.72, 0.72);
		foregrounds1.updateHitbox();
		add(foregrounds1);
/*
		var foregrounds2:FunkinSprite = new FunkinSprite(687, 50, true);
		foregrounds2.frames = Paths.getPath('menus/mods/foreground-wires', 'animated');
		foregrounds2.addAnim('idle', 'Wires', 24, true);
		foregrounds2.antialiasing = SaveData.data.antialiasing;
		foregrounds2.playAnim('idle');
		foregrounds2.scale.set(0.72, 0.72);
		foregrounds2.updateHitbox();
		add(foregrounds2);*/

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
			if (ModsRegistry.currentMod == ModsRegistry.mods[curSelected]) {
				FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
				return;
			}

			acceptOption = true;
			ModsRegistry.onMod = true;
			ModsRegistry.currentMod = ModsRegistry.mods[curSelected];

			SaveData.data.currentMod = ModsRegistry.currentMod;
			SaveData.data.onMod = true;
			SaveData.flush();

			trace("Mod actual: " + ModsRegistry.currentMod);

			FlxTimer.wait(0.1, () -> {
				Library.reloadMods();
				MusicBeatState.switchState(() -> new core.ConfigMain());
			});
		}

		if (Controls.BACK)
			ScriptClass.switchState('MainMenuState');
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

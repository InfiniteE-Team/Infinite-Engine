package states.menus;

import sys.FileSystem;
import core.assets.Library;
import core.api.WindowAPI;
import core.assets.Library;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import modding.mods.ModData;
import core.assets.FunkinSprite;
import modding.mods.ModsRegistry;

class ModsState extends states.MusicBeatState {
	var curSelected:Int = 0;

	var listModTitles:Array<FlxText> = [];
	var listMods:Array<FlxText> = [];
	var listGraphics:Array<FunkinSprite> = [];

	var acceptOption:Bool = false;

	var boyfriend:FunkinSprite;
	var gf:FunkinSprite;
	var carbattery:FunkinSprite;

	var noModsText:FlxText;

	var changeMod:Bool = false;

	var dragPlugin:states.menus.objects.ModDropPlugin;

	public function new() {
		super();
	}

	function reloadModMenu() {
		Library.reloadMods();

		for (i in 0...ModsRegistry.mods.length) {
			var graphic = Paths.getPath('iconMod', 'image');
			if (!FileSystem.exists(graphic))
				graphic = Paths.getPath('menus/mods/fallback-icon', 'image');

			var spacing:Float = 110;

			var image:FunkinSprite = new FunkinSprite(200, 200 + (i * spacing), true);
			image.loadGraphic(graphic);
			image.antialiasing = SaveData.data.antialiasing;
			image.ID = i;
			image.scrollFactor.set(0, 0);
			image.scale.set(0.72, 0.72);
			image.updateHitbox();
			listGraphics.push(image);
			add(image);

			var mod:FlxText = new FlxText(330, 210 + (i * spacing), FlxG.width, ModsRegistry.mods[i].toUpperCase());
			mod.setFormat(Paths.getPath('Funkin.otf', 'font'), 32, 0xFFFFFFFF, "left");
			mod.antialiasing = SaveData.data.antialiasing;
			mod.ID = i;
			mod.scrollFactor.set(0, 0);
			listMods.push(mod);
			listModTitles.push(mod);
			add(mod);

			var description:String = '??';
			if (modding.mods.ModConfig.modData != null && modding.mods.ModConfig.modData.description != null) {
				description = modding.mods.ModConfig.modData.description;
			}

			var modDesc:FlxText = new FlxText(330, 240 + (i * spacing), FlxG.width, description);
			modDesc.setFormat(Paths.getPath('Funkin.otf', 'font'), 32, 0xFFFFFFFF, "left");
			modDesc.antialiasing = SaveData.data.antialiasing;
			modDesc.ID = i;
			modDesc.scrollFactor.set(0, 0);
			listMods.push(modDesc);
			add(modDesc);
		}

		changeSelection(0);
	}

	override public function create() {
		super.create();

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/mod-menu-ambience/mod-menu-ambience', 'music'), 0.8, 67);

		var bg:FunkinSprite = new FunkinSprite(0, 0, true);
		bg.loadGraphic(Paths.getPath('menus/mods/bg', 'image'));
		bg.scale.set(0.665, 0.665);
		bg.updateHitbox();
		bg.antialiasing = SaveData.data.antialiasing;
		bg.screenCenter();
		add(bg);

		var bgwires:FunkinSprite = new FunkinSprite(1030, 260, true);
		bgwires.loadGraphic(Paths.getPath('menus/mods/bgwires', 'image'));
		bgwires.scale.set(0.72, 0.72);
		bgwires.updateHitbox();
		bgwires.antialiasing = SaveData.data.antialiasing;
		add(bgwires);

		carbattery = new FunkinSprite(970, 100, true);
		carbattery.frames = Paths.getPath('menus/mods/carbattery', 'animated');
		carbattery.addAnim('idle', 'idle', 24, false, [0]);
		carbattery.addAnim('press', 'idle', 24, true);
		carbattery.antialiasing = SaveData.data.antialiasing;
		carbattery.playAnim('idle');
		carbattery.scale.set(0.72, 0.72);
		carbattery.updateHitbox();
		add(carbattery);

		var box:FunkinSprite = new FunkinSprite(140, 150, true);
		box.loadGraphic(Paths.getPath('menus/mods/box', 'image'));
		box.antialiasing = SaveData.data.antialiasing;
		box.scrollFactor.set(0, 0);
		box.scale.set(0.9, 0.6);
		box.updateHitbox();
		add(box);

		if (ModsRegistry.mods.length == 0) {
			noModsText = new FlxText(0, FlxG.height * 0.45, FlxG.width, "NO MODS FOUND");
			noModsText.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFFFFF, "center");
			noModsText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 3, 1);
			noModsText.antialiasing = SaveData.data.antialiasing;
			noModsText.scrollFactor.set(0, 0);
			add(noModsText);
		} else
			reloadModMenu();

		gf = createChars(732, 123, 'characters/gf');
		gf.addAnim('idle', 'gf idle', 24, true);
		gf.addAnim('press', 'electrocuted', 24, true);
		gf.offsets.set('press', {x: 0, y: -200});
		gf.playAnim('idle');
		add(gf);

		boyfriend = createChars(876, 152, 'characters/bf');
		boyfriend.addAnim('idle', 'bf idle', 24, true);
		boyfriend.addAnim('press', 'electrocuted', 24, true);
		boyfriend.playAnim('idle');
		add(boyfriend);

		for (charsAnim in [boyfriend, gf]) {
			charsAnim.addAnim('crispy', 'crispy', 24, false);
			charsAnim.addAnim('crispy-loop', 'crispy loop', 24, true);
		}

		gf.offsets.set('crispy', {x: 0, y: -200});

		var foregrounds1:FunkinSprite = new FunkinSprite(687, 50, true);
		foregrounds1.frames = Paths.getPath('menus/mods/foreground-wires', 'animated');
		foregrounds1.addAnim('idle', 'idle', 24, true);
		foregrounds1.antialiasing = SaveData.data.antialiasing;
		foregrounds1.playAnim('idle');
		foregrounds1.scale.set(0.72, 0.72);
		foregrounds1.updateHitbox();
		add(foregrounds1);

		var dragPacksDesc:FlxText = new FlxText(140, 100, FlxG.width, 'DRAG PACKS ONTO THIS WINDOW TO ADD NEW STUFF');
		dragPacksDesc.setFormat(Paths.getPath('Funkin.otf', 'font'), 32, 0xFFFFFFFF, "left");
		dragPacksDesc.antialiasing = SaveData.data.antialiasing;
		dragPacksDesc.scrollFactor.set(0, 0);
		add(dragPacksDesc);

		var toptext:FunkinSprite = new FunkinSprite(325, 32, true);
		toptext.loadGraphic(Paths.getPath('menus/mods/top-text', 'image'));
		toptext.antialiasing = SaveData.data.antialiasing;
		toptext.scale.set(0.7, 0.7);
		toptext.updateHitbox();
		add(toptext);

		/*
			var foregrounds2:FunkinSprite = new FunkinSprite(687, 50, true);
			foregrounds2.frames = Paths.getPath('menus/mods/foreground-wires', 'animated');
			foregrounds2.addAnim('idle', 'Wires', 24, true);
			foregrounds2.antialiasing = SaveData.data.antialiasing;
			foregrounds2.playAnim('idle');
			foregrounds2.scale.set(0.72, 0.72);
			foregrounds2.updateHitbox();
			add(foregrounds2); */

		dragPlugin = new states.menus.objects.ModDropPlugin(this, () -> {
			for (item in listMods) {
				remove(item);
				item.destroy();
			}
			for (icon in listGraphics) {
				remove(icon);
				icon.destroy();
			}

			if (noModsText != null) {
				remove(noModsText);
				noModsText.destroy();
				noModsText = null;
			}

			listMods.resize(0);
			listModTitles.resize(0);
			listGraphics.resize(0);

			FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));

			reloadModMenu();
		});
	}

	function createChars(x:Float, y:Float, char:String):FunkinSprite {
		var spr = new FunkinSprite(x, y, true);
		spr.frames = Paths.getPath('menus/mods/' + char, 'animated');
		spr.antialiasing = SaveData.data.antialiasing;
		spr.scale.set(0.72, 0.72);
		spr.updateHitbox();
		return spr;
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
			acceptOption = true;

			if (ModsRegistry.currentMod == ModsRegistry.mods[curSelected]) {
				FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
				acceptOption = false;
				return;
			}

			for (electrocuted in [boyfriend, gf, carbattery])
				electrocuted.playAnim('press');

			FlxTimer.wait(2, () -> {
				FlxG.sound.play(Paths.getPath('menus/mods/smoke-cloud', 'sound'));
				FlxG.camera.flash(0xFFFFFFFF, 2);
				acceptOption = false;

				for (electrocuted in [boyfriend, gf]){
					electrocuted.playAnim('crispy');

					if (electrocuted.isFinished('crispy'))
						electrocuted.playAnim('crispy-loop');
				}

				carbattery.playAnim('idle');

				initMod();
			});
		}

		if (Controls.BACK) {
			if (changeMod)
				FlxG.switchState(() -> new core.ConfigMain());
			else
				modding.scripting.types.ScriptClass.switchState('MainMenuState');
		}
	}

	function initMod() {
		ModsRegistry.onMod = true;
		ModsRegistry.currentMod = ModsRegistry.mods[curSelected];

		SaveData.data.currentMod = ModsRegistry.currentMod;
		SaveData.data.onMod = true;
		SaveData.flush();

		changeSelection(0);

		trace("Mod actual: " + ModsRegistry.currentMod);

		FlxTimer.wait(0.1, () -> {
			Library.reloadMods();
		});

		changeMod = true;
	}

	function changeSelection(change:Int = 0):Void {
		curSelected += change;

		if (curSelected < 0)
			curSelected = ModsRegistry.mods.length - 1;
		if (curSelected >= ModsRegistry.mods.length)
			curSelected = 0;

		for (i in 0...listModTitles.length) {
			var baseName = ModsRegistry.mods[i].toUpperCase();
			if (ModsRegistry.mods[i] == ModsRegistry.currentMod)
				listModTitles[i].text = baseName + ' (SELECTED)';
			else
				listModTitles[i].text = baseName;
		}

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

	override public function destroy() {
		if (dragPlugin != null) {
			dragPlugin.destroy();
		}
		super.destroy();
	}
}

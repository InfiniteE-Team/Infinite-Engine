package states.menus;

import game.objects.Camera;
import haxe.io.Path;
import sys.FileSystem;
import core.assets.Library;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import core.assets.FunkinSprite;
import modding.mods.ModsRegistry;

typedef ModEntry = {
	var icon:FunkinSprite;
	var title:FlxText;
	var desc:FlxText;

	var shownTitle:String;
}

class ModsState extends MusicBeatState {
	var curSelected:Int = 0;

	var entries:Array<ModEntry> = [];

	var acceptOption:Bool = false;

	var boyfriend:FunkinSprite;
	var gf:FunkinSprite;
	var carbattery:FunkinSprite;

	var noModsText:FlxText;
	var deleteHint:FlxText;

	var pendingDelete:Int = -1;

	var changeMod:Bool = false;

	var camMods:Camera;

	var dragPlugin:states.menus.objects.ModDropPlugin;

	static final BOX_X:Int = 140;
	static final BOX_Y:Int = 150;
	static final BOX_W:Int = 910;
	static final BOX_H:Int = 412;

	static final LIST_TOP:Float = 80;
	static final ITEM_SPACING:Float = 110;

	static final CAM_SCROLL_PADDING:Float = 20;

	static final SCROLL_SPEED:Float = 12;

	static final SCROLLBAR_X:Int = 700;
	static final SCROLLBAR_W:Int = 6;

	static final TITLE_MAX_WIDTH:Float = 380;
	static final DESC_MAX_WIDTH:Float = 380;
	static final DESC_SIZE:Int = 24;

	static final DOUBLE_CLICK_TIME:Float = 0.4;

	var scrollbar:flixel.FlxSprite;
	var scrollbarTrack:flixel.FlxSprite;

	var targetScroll:Float = 0;
	var maxScroll:Float = 0;
	var thumbH:Float = 40;

	var sinceClick:Float = 99;
	var lastClickIndex:Int = -1;

	var mouseWasVisible:Bool = false;

	public function new() {
		super();
	}

	function reloadModMenu() {
		Library.reloadMods();

		for (i in 0...ModsRegistry.mods.length) {
			var modName = ModsRegistry.mods[i];
			var modsFolder = core.assets.Library.modsFolder;

			var graphic = '$modsFolder/$modName/images/iconMod.png';
			if (!sys.FileSystem.exists(graphic))
				graphic = Paths.getPath('menus/mods/fallback-icon', 'image');

			var modMeta = modding.mods.ModData.ModConfig.loadForMod(modName);
			var description:String = modMeta == null ? '(NO DATA/META.JSON FOUND)' : (modMeta.description ?? '??');

			var itemY:Float = LIST_TOP + (i * ITEM_SPACING);

			var image:FunkinSprite = new FunkinSprite(40, itemY, true);
			image.loadGraphic(graphic);
			image.antialiasing = SaveData.data.antialiasing;
			image.scale.set(0.72, 0.72);
			image.cameras = [camMods];
			image.updateHitbox();
			add(image);

			var mod:FlxText = new FlxText(160, itemY + 10, FlxG.width, '');
			mod.setFormat(Paths.getPath('Funkin.otf', 'font'), 32, 0xFFFFFFFF, "left");
			fitText(mod, modName.toUpperCase(), TITLE_MAX_WIDTH);
			mod.antialiasing = SaveData.data.antialiasing;
			mod.cameras = [camMods];
			add(mod);

			var modDesc:FlxText = new FlxText(160, itemY + 40, FlxG.width, '');
			modDesc.setFormat(Paths.getPath('Funkin.otf', 'font'), DESC_SIZE, 0xFFFFFFFF, "left");
			fitText(modDesc, description, DESC_MAX_WIDTH);
			modDesc.antialiasing = SaveData.data.antialiasing;
			modDesc.cameras = [camMods];
			add(modDesc);

			entries.push({
				icon: image,
				title: mod,
				desc: modDesc,
				shownTitle: ''
			});
		}

		changeSelection(0);
	}

	override public function create() {
		super.create();

		mouseWasVisible = FlxG.mouse.visible;
		FlxG.mouse.visible = true;

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/mod-menu-ambience/mod-menu-ambience', 'music'), 0.8, 67);

		camMods = new Camera(BOX_X, BOX_Y, BOX_W, BOX_H);
		camMods.bgColor = 0x00000000;
		FlxG.cameras.add(camMods, false);
		this.camera = FlxG.camera;

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

		scrollbarTrack = new flixel.FlxSprite(SCROLLBAR_X, BOX_Y + 8);
		scrollbarTrack.makeGraphic(SCROLLBAR_W, BOX_H - 16, 0x33FFFFFF);
		scrollbarTrack.scrollFactor.set(0, 0);
		add(scrollbarTrack);

		scrollbar = new flixel.FlxSprite(SCROLLBAR_X, BOX_Y + 8);
		scrollbar.makeGraphic(SCROLLBAR_W, 40, 0xFFFFFFFF);
		scrollbar.scrollFactor.set(0, 0);
		add(scrollbar);

		if (ModsRegistry.mods.length == 0)
			showNoModsText();
		else
			reloadModMenu();

		updateScrollLimits();
		snapScroll();

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

		deleteHint = new FlxText(140, 575, FlxG.width, '');
		deleteHint.setFormat(Paths.getPath('Funkin.otf', 'font'), 24, 0xFFFFFFFF, "left");
		deleteHint.antialiasing = SaveData.data.antialiasing;
		deleteHint.scrollFactor.set(0, 0);
		add(deleteHint);
		updateDeleteHint();

		var toptext:FunkinSprite = new FunkinSprite(325, 32, true);
		toptext.loadGraphic(Paths.getPath('menus/mods/top-text', 'image'));
		toptext.antialiasing = SaveData.data.antialiasing;
		toptext.scale.set(0.7, 0.7);
		toptext.updateHitbox();
		add(toptext);

		dragPlugin = new states.menus.objects.ModDropPlugin(this, () -> {
			FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));

			rebuildModMenu();
		});
	}

	function fitText(txt:FlxText, full:String, maxWidth:Float, suffix:String = ''):Void {
		txt.text = full + suffix;

		if (txt.textField.textWidth <= maxWidth)
			return;

		var cut = full.length;
		while (cut > 1 && txt.textField.textWidth > maxWidth) {
			cut--;
			txt.text = full.substr(0, cut) + '...' + suffix;
		}
	}

	function showNoModsText():Void {
		noModsText = new FlxText(0, FlxG.height * 0.45, FlxG.width, "NO MODS FOUND");
		noModsText.setFormat(Paths.getPath('Funkin.otf', 'font'), 42, 0xFFFFFFFF, "center");
		noModsText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 3, 1);
		noModsText.antialiasing = SaveData.data.antialiasing;
		noModsText.scrollFactor.set(0, 0);
		add(noModsText);
	}

	function rebuildModMenu():Void {
		for (entry in entries) {
			var items:Array<flixel.FlxSprite> = [entry.icon, entry.title, entry.desc];
			for (item in items) {
				remove(item);
				item.destroy();
			}
		}
		entries.resize(0);

		if (noModsText != null) {
			remove(noModsText);
			noModsText.destroy();
			noModsText = null;
		}

		FlxG.cameras.remove(camMods, true);
		camMods = new Camera(BOX_X, BOX_Y, BOX_W, BOX_H);
		camMods.bgColor = 0x00000000;
		FlxG.cameras.add(camMods, false);

		pendingDelete = -1;
		lastClickIndex = -1;
		reloadModMenu();

		if (ModsRegistry.mods.length == 0)
			showNoModsText();

		updateScrollLimits();
		snapScroll();
		updateDeleteHint();
	}

	function updateDeleteHint():Void {
		if (deleteHint == null)
			return;

		if (ModsRegistry.mods.length == 0) {
			deleteHint.text = '';
		} else if (pendingDelete >= 0 && pendingDelete < ModsRegistry.mods.length) {
			deleteHint.text = 'PRESS DELETE AGAIN TO REMOVE ' + ModsRegistry.mods[pendingDelete].toUpperCase() + ' (MOVING CANCELS)';
			deleteHint.color = 0xFFFF5555;
		} else {
			deleteHint.text = 'PRESS DELETE TO REMOVE THE SELECTED MOD';
			deleteHint.color = 0xFFFFFFFF;
		}
	}

	function deleteSelectedMod():Void {
		var modName = ModsRegistry.mods[curSelected];
		var modPath = Path.join([core.assets.Library.modsFolder, modName]);

		try {
			deleteFolder(modPath);
		} catch (e:Dynamic) {
			trace('Could not delete mod "$modName": $e');
			FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
			pendingDelete = -1;
			updateDeleteHint();
			return;
		}

		trace('Mod deleted: $modName');

		var wasActive = ModsRegistry.currentMod == modName;

		if (curSelected > 0)
			curSelected--;

		FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
		rebuildModMenu();

		if (wasActive) {
			SaveData.data.currentMod = ModsRegistry.currentMod;
			SaveData.data.onMod = ModsRegistry.onMod;
			SaveData.flush();
			changeMod = true;
		}
	}

	function deleteFolder(path:String):Void {
		if (isLink(path)) {
			FileSystem.deleteFile(path);
			return;
		}

		for (entry in FileSystem.readDirectory(path)) {
			var child = Path.join([path, entry]);
			if (FileSystem.isDirectory(child))
				deleteFolder(child);
			else
				FileSystem.deleteFile(child);
		}

		FileSystem.deleteDirectory(path);
	}

	function isLink(path:String):Bool {
		var parent = Path.directory(path);
		var expected = Path.join([FileSystem.fullPath(parent == '' ? '.' : parent), Path.withoutDirectory(path)]);
		return Path.normalize(FileSystem.fullPath(path)) != Path.normalize(expected);
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

		updateScroll(elapsed);

		if (acceptOption)
			return;

		if (ModsRegistry.mods.length > 0) {
			if (Controls.UI_UP)
				changeSelection(-1);

			if (Controls.UI_DOWN)
				changeSelection(1);

			handleMouse(elapsed);

			if (FlxG.keys.justPressed.DELETE || FlxG.keys.justPressed.BACKSPACE) {
				if (pendingDelete == curSelected) {
					deleteSelectedMod();
				} else {
					pendingDelete = curSelected;
					FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'));
					updateDeleteHint();
				}
			}
		}

		if (Controls.ACCEPT)
			acceptSelectedMod();

		if (Controls.BACK) {
			if (camMods != null) {
				FlxG.cameras.remove(camMods, true);
			}

			if (changeMod) {
				#if DISCORD_ALLOWED
				core.api.DiscordAPI.instance.shutdown();
				#end
				FlxG.switchState(() -> new core.ConfigMain());
			} else
				modding.scripting.types.ScriptClass.switchState('MainMenuState');
		}
	}

	function handleMouse(elapsed:Float):Void {
		sinceClick += elapsed;

		updateHover();

		if (FlxG.mouse.wheel != 0) {
			var next = curSelected + (FlxG.mouse.wheel > 0 ? -1 : 1);
			if (next >= 0 && next < ModsRegistry.mods.length)
				changeSelection(next - curSelected);
		}

		if (!FlxG.mouse.justPressed || camMods == null)
			return;

		var localX:Float = FlxG.mouse.x - BOX_X;
		var localY:Float = FlxG.mouse.y - BOX_Y;

		if (localX < 0 || localX > SCROLLBAR_X - BOX_X || localY < 0 || localY > BOX_H)
			return;

		var index:Int = Math.floor((localY + camMods.scroll.y - LIST_TOP) / ITEM_SPACING);
		if (index < 0 || index >= ModsRegistry.mods.length)
			return;

		if (index == lastClickIndex && sinceClick <= DOUBLE_CLICK_TIME) {
			lastClickIndex = -1;
			acceptSelectedMod();
		} else {
			lastClickIndex = index;
			sinceClick = 0;

			FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));

			if (index != curSelected)
				changeSelection(index - curSelected);
		}
	}

	function getHoveredIndex():Int {
		if (camMods == null)
			return -1;

		var localX:Float = FlxG.mouse.x - BOX_X;
		var localY:Float = FlxG.mouse.y - BOX_Y;

		if (localX < 0 || localX > SCROLLBAR_X - BOX_X || localY < 0 || localY > BOX_H)
			return -1;

		var index:Int = Math.floor((localY + camMods.scroll.y - LIST_TOP) / ITEM_SPACING);
		return (index >= 0 && index < ModsRegistry.mods.length) ? index : -1;
	}

	function updateHover():Void {
		var hovered = getHoveredIndex();

		for (i in 0...entries.length) {
			if (i == curSelected)
				continue;

			var over = i == hovered;
			for (txt in [entries[i].title, entries[i].desc]) {
				txt.alpha = over ? 0.9 : 0.6;
				txt.color = over ? 0xFFFFFFAA : 0xFFFFFFFF;
			}
		}
	}

	function acceptSelectedMod():Void {
		if (acceptOption || ModsRegistry.mods.length == 0)
			return;

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

			for (electrocuted in [boyfriend, gf]) {
				electrocuted.playAnim('crispy');

				if (electrocuted.isFinished('crispy'))
					electrocuted.playAnim('crispy-loop');
			}

			carbattery.playAnim('idle');

			initMod();
		});
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

		if (change != 0 && pendingDelete != -1) {
			pendingDelete = -1;
			updateDeleteHint();
		}

		if (curSelected < 0)
			curSelected = ModsRegistry.mods.length - 1;
		if (curSelected >= ModsRegistry.mods.length)
			curSelected = 0;

		updateScrollLimits();

		if (ModsRegistry.mods.length > 0) {
			var itemCenterY:Float = LIST_TOP + (curSelected * ITEM_SPACING) + (ITEM_SPACING * 0.5);
			targetScroll = Math.max(0, Math.min(itemCenterY - (BOX_H * 0.5), maxScroll));
		} else
			targetScroll = 0;

		for (i in 0...entries.length) {
			var entry = entries[i];

			var suffix = ModsRegistry.mods[i] == ModsRegistry.currentMod ? ' (SELECTED)' : '';
			var label = ModsRegistry.mods[i].toUpperCase() + suffix;
			if (entry.shownTitle != label) {
				fitText(entry.title, ModsRegistry.mods[i].toUpperCase(), TITLE_MAX_WIDTH, suffix);
				entry.shownTitle = label;
			}

			var selected = i == curSelected;
			for (txt in [entry.title, entry.desc]) {
				txt.alpha = selected ? 1.0 : 0.6;
				txt.color = selected ? 0xFFFFFF00 : 0xFFFFFFFF;
			}
		}
	}

	function getContentHeight():Float
		return LIST_TOP + (ModsRegistry.mods.length * ITEM_SPACING);

	function updateScrollLimits():Void {
		maxScroll = Math.max(0, getContentHeight() - BOX_H + CAM_SCROLL_PADDING);

		if (scrollbar == null)
			return;

		scrollbar.visible = scrollbarTrack.visible = ModsRegistry.mods.length > 0;

		var trackH:Float = BOX_H - 16;
		thumbH = maxScroll <= 0 ? trackH : Math.max(20, trackH * Math.min(1.0, BOX_H / getContentHeight()));

		scrollbar.setGraphicSize(SCROLLBAR_W, Std.int(thumbH));
		scrollbar.updateHitbox();
		updateScrollbarPosition();
	}

	function updateScrollbarPosition():Void {
		if (scrollbar == null || camMods == null)
			return;

		var trackH:Float = BOX_H - 16;
		var trackY:Float = BOX_Y + 8;

		if (maxScroll <= 0) {
			scrollbar.y = trackY;
			return;
		}

		var scrollRatio:Float = Math.max(0, Math.min(camMods.scroll.y / maxScroll, 1));
		scrollbar.y = trackY + scrollRatio * (trackH - thumbH);
	}

	function updateScroll(elapsed:Float):Void {
		if (camMods == null)
			return;

		var current:Float = camMods.scroll.y;

		if (Math.abs(current - targetScroll) < 0.5)
			camMods.scroll.y = targetScroll;
		else
			camMods.scroll.y = current + (targetScroll - current) * (1 - Math.exp(-SCROLL_SPEED * elapsed));

		updateScrollbarPosition();
	}

	function snapScroll():Void {
		if (camMods == null)
			return;

		camMods.scroll.y = targetScroll;
		updateScrollbarPosition();
	}

	override public function destroy() {
		if (dragPlugin != null) {
			dragPlugin.destroy();
		}
		if (camMods != null) {
			FlxG.cameras.remove(camMods, true);
		}
		camMods = null;
		FlxG.mouse.visible = mouseWasVisible;
		super.destroy();
	}
}
package modding.editors;

import flixel.math.FlxMath;
import game.objects.Camera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import core.assets.FunkinSprite;
import game.objects.sprites.Character;
import modding.editors.ui.SelectionObj;
import core.json.editors.EditorAction;
import flixel.addons.display.FlxGridOverlay;
// ui
import modding.editors.ui.*;

class CharacterEditor extends MusicBeatState {
	var camEditor:Camera;
	var camHud:Camera;

	// camera on char
	var isDragging:Bool = false;
	var dragOffsetX:Float = 0;
	var dragOffsetY:Float = 0;
	var hoverText:FlxText;

	var sectionTab:SectionTab;
	var tabAnimGroup:flixel.group.FlxGroup;
	var tabLayersGroup:flixel.group.FlxGroup;

	// camera on camera Editor
	var isCamDragging:Bool = false;

	// character
	var info:FlxText;
	var infoAnim:FlxText;

	// import error display
	var importErrorText:FlxText;
	var importErrorTimer:flixel.util.FlxTimer;

	// left tab
	var animButtons:Array<StatsButton> = [];
	var layerButtons:Array<StatsButton> = [];

	var selectedLayer:FunkinSprite = null;
	var selectedLayerName:String = '';
	var activeAnim:String = '';
	var importedLayers:Array<{sprite:FunkinSprite, name:String, path:String}> = [];
	var selectionObj:SelectionObj;

	// drags
	var undoStack:Array<EditorAction> = [];
	var redoStack:Array<EditorAction> = [];

	var dragStartX:Float = 0;
	var dragStartY:Float = 0;
	var offsetEditing:Bool = false;
	var offsetStartX:Float = 0;
	var offsetStartY:Float = 0;
	var savedUndoLength:Int = 0;

	public var char:Character = null;

	var ghostChar:Character = null;

	public var curCharacter:String = 'bf';

	var keysLocked:Bool = false;

	var advertency:FlxText;

	public function new(curCharacter:String) {
		super();
		this.curCharacter = curCharacter;
	}

	function createCameras() {
		camEditor = new Camera();
		camHud = new Camera();
		camHud.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);

		camEditor.zoom = 0.9;

		FlxG.cameras.add(camHud, false);
	}

	override public function create() {
		super.create();

		if (FlxG.mouse != null)
			FlxG.mouse.visible = true;

		core.audio.MasterAudio.playMenu(Paths.getPath('menus/artistic-expression/artistic-expression', 'music'), 0.6, 137);

		createCameras();

		if (core.ui.FPSCounter.instance != null)
			core.ui.FPSCounter.instance.visible = false;

		final tile = FlxGridOverlay.createGrid(32, 32, FlxG.width * 5, FlxG.height * 5, true, 0xFF2C2C2C, 0xFF1F1F1F);
		final grid = new flixel.FlxSprite(-(FlxG.width * 5) * 0.32, -(FlxG.height * 5) * 0.3);
		grid.loadGraphic(tile);
		grid.scrollFactor.set(0, 0);
		add(grid);

		selectionObj = new SelectionObj();
		add(selectionObj);

		createHUD();

		ghostChar = loadCharacter('idk', curCharacter, 0, 0);
		ghostChar.alpha = 0.7;
		for (layer in ghostChar.layers)
			layer.alpha = 0.7;
		ghostChar.visible = false;

		char = loadCharacter('idk', curCharacter, 0, 0);

		centerCameraOnChar();

		if (char.characterData != null
			&& char.characterData.render != null
			&& char.characterData.render.layers != null
			&& char.characterData.render.layers.length > 0) {
			refreshAnimList(char.characterData.render.layers[0].name);
			refreshLayerList();
		}
		refreshCharProps();

		FlxG.cameras.remove(camHud, false);
		FlxG.cameras.add(camHud, false);
	}

	function loadCharacter(id:String, name:String, x:Float, y:Float):Character {
		var char = new Character(id, name, x, y);
		if (char == null)
			return null;
		char.editorMode = true;

		for (layer in char.layers)
			layer.setPosition(layer.x + char.x, layer.y + char.y);

		for (layer in char.layers)
			add(layer);
		add(char);

		if (char.layers.length > 0) {
			selectedLayer = char.layers[0];
			for (name => sprite in char.layerMap)
				if (sprite == selectedLayer) {
					selectedLayerName = name;
					break;
				}
		}

		return char;
	}

	function createHUD() {
		// animations
		tabAnimGroup = new flixel.group.FlxGroup();
		tabLayersGroup = new flixel.group.FlxGroup();

		sectionTab = new SectionTab(25, 30, 255, 0.3, [{label: 'ANIMATIONS'}, {label: 'LAYERS'}], camHud, (index) -> {
			tabAnimGroup.visible = index == 0;
			tabLayersGroup.visible = index == 1;
		});
		sectionTab.cameras = [camHud];
		tabLeft();

		add(tabAnimGroup);
		add(tabLayersGroup);

		scrollTrack = new flixel.FlxSprite(278, LIST_TOP).loadGraphic(Paths.getPath('menus/editors/ui/slidebar', 'image'));
		scrollTrack.setGraphicSize(scrollTrack.width, LIST_BOTTOM - LIST_TOP);
		scrollTrack.updateHitbox();
		scrollTrack.alpha = 0.35;
		scrollTrack.cameras = [camHud];
		add(scrollTrack);

		scrollThumb = new flixel.FlxSprite(278, LIST_TOP).loadGraphic(Paths.getPath('menus/editors/ui/slidebar', 'image'));
		scrollThumb.color = 0xFFCC0040;
		scrollThumb.cameras = [camHud];
		add(scrollThumb);

		add(sectionTab);

		tabLayersGroup.visible = false;

		hoverText = new FlxText(0, 0, 0, '');
		hoverText.setFormat(null, 14, FlxColor.YELLOW, 'left');
		hoverText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		hoverText.scrollFactor.set(0, 0);
		hoverText.cameras = [camHud];
		add(hoverText);

		tabRight();

		var path = Paths.getPath('data/game/characters');
		var chars:Array<String> = [];
		if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path)) {
			chars = sys.FileSystem.readDirectory(path).map(function(file) {
				return StringTools.replace(file, '.json', '');
			});
			curCharacter = chars[0];
		} else
			Console.log('Chars data not loading in list');

		final dd2 = new DropDown(0, 30, curCharacter, chars, function(selected) {
			for (layer in ghostChar.layers)
				remove(ghostChar, true);
			remove(ghostChar, true);
			ghostChar.destroy();
			ghostChar = null;

			if (char == null)
				return;

			for (layer in char.layers)
				remove(layer, true);
			remove(char, true);
			char.destroy();
			char = null;

			for (imported in importedLayers) {
				remove(imported.sprite, true);
				imported.sprite.destroy();
			}
			importedLayers = [];
			clearHistory();
			selectedLayer = null;
			selectedLayerName = '';

			curCharacter = selected;
			ghostChar = loadCharacter('idk', selected, 0, 0);
			ghostChar.alpha = 0.7;
			for (layer in ghostChar.layers)
				layer.alpha = 0.7;
			ghostChar.visible = false;

			char = loadCharacter('idk', selected, 0, 0);

			if (char.characterData != null
				&& char.characterData.render != null
				&& char.characterData.render.layers != null
				&& char.characterData.render.layers.length > 0) {
				refreshAnimList(char.characterData.render.layers[0].name);
				refreshLayerList();
			}
			refreshCharProps();
			animPropsKey = '';

			centerCameraOnChar();
		}, camHud);
		dd2.screenCenter(X);
		dd2.cameras = [camHud];
		add(dd2);

		final watermark = new FlxText(0, FlxG.height * 0.94, 0, 'Character Editor (PROTOTYPE)');
		watermark.setFormat(Paths.getPath('Funkin.otf', 'font'), 24, FlxColor.WHITE, 'right');
		watermark.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		watermark.scrollFactor.set(0, 0);
		watermark.x = FlxG.width - watermark.width;
		watermark.cameras = [camHud];
		add(watermark);

		advertency = new FlxText(20, FlxG.height * 0.9, 0, 'Unsaved Changes (Ctrl/Cmd+S to save)');
		advertency.setFormat(Paths.getPath('Funkin.otf', 'font'), 24, FlxColor.RED, 'left');
		advertency.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		advertency.scrollFactor.set(0, 0);
		advertency.visible = false;
		advertency.cameras = [camHud];
		add(advertency);
	}

	var tab2:Tab;

	function tabLeft() {
		tab2 = new Tab(10, 20, 'Símbolo 10');
		tab2.cameras = [camHud];
		add(tab2);

		buildAnimTab();
		buildLayersTab();
	}

	function buildAnimTab() {
		final pan = new flixel.FlxSprite(0, 0).loadGraphic(Paths.getPath('menus/editors/ui/pan', 'image'));
		pan.scrollFactor.set(0, 0);
		pan.antialiasing = SaveData.data.antialiasing;
		pan.scale.set(0.6, 0.6);
		pan.updateHitbox();
		pan.cameras = [camHud];
		tabAnimGroup.add(pan);
		tab2.addItem(pan, 15, 70);

		infoAnim = new FlxText(30, 95, FlxG.width, "Idle [0/0]\nOffset: [0, 0]");
		infoAnim.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFF181818, 'left');
		infoAnim.scrollFactor.set(0, 0);
		infoAnim.cameras = [camHud];
		tabAnimGroup.add(infoAnim);

		newAnimButton = new ButtonPlus(20, 180, 'New Anim', addNewAnim, camHud);
		newAnimButton.scrollFactor.set(0, 0);
		newAnimButton.cameras = [camHud];
		tabAnimGroup.add(newAnimButton);

		if (char != null
			&& char.characterData != null
			&& char.characterData.render != null
			&& char.characterData.render.layers != null
			&& char.characterData.render.layers.length > 0) {
			refreshAnimList(char.characterData.render.layers[0].name);
			refreshLayerList();
		}
	}

	function buildLayersTab() {
		final pan = new flixel.FlxSprite(0, 0).loadGraphic(Paths.getPath('menus/editors/ui/pan', 'image'));
		pan.scrollFactor.set(0, 0);
		pan.antialiasing = SaveData.data.antialiasing;
		pan.scale.set(0.6, 0.6);
		pan.updateHitbox();
		pan.cameras = [camHud];
		tabLayersGroup.add(pan);
		tab2.addItem(pan, 15, 70);

		info = new FlxText(30, 95, FlxG.width, "char x: \nchar y: ");
		info.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFF181818, 'left');
		info.scrollFactor.set(0, 0);
		info.cameras = [camHud];
		tabLayersGroup.add(info);
	}

	// right side
	var propsTab:SectionTab;
	var animPropGroup:flixel.group.FlxGroup;
	var charPropGroup:flixel.group.FlxGroup;

	var filesText:FlxText;
	var gameOverInput:flixel.text.FlxInputText;
	var camX:NumberStepper;
	var camY:NumberStepper;
	var charX:NumberStepper;
	var charY:NumberStepper;
	var alphaStepper:NumberStepper;
	var sizeStepper:NumberStepper;
	var playableBox:CheckBox;
	var flipXBox:CheckBox;
	var flipYBox:CheckBox;

	var newAnimButton:ButtonPlus;

	// left lists scroll inside the panel -JloorDev
	static final LIST_TOP:Float = 180;
	static final LIST_BOTTOM:Float = 610;
	static final ROW:Float = 40;

	var listScroll:Float = 0;
	var scrollTrack:flixel.FlxSprite;
	var scrollThumb:flixel.FlxSprite;
	var draggingThumb:Bool = false;
	var animNameInput:flixel.text.FlxInputText;
	var animPrefixInput:flixel.text.FlxInputText;
	var offsetX:NumberStepper;
	var offsetY:NumberStepper;
	var fpsStepper:NumberStepper;
	var loopBox:CheckBox;
	var animPropsKey:String = '';

	function tabRight() {
		final px = FlxG.width * 0.72;
		final py = 20.0;

		final tab = new Tab(px, py, 'Símbolo 9');
		tab.cameras = [camHud];
		add(tab);

		final lowerTab = new Tab(px, py + 320, 'Símbolo 9');
		lowerTab.cameras = [camHud];
		add(lowerTab);

		animPropGroup = new flixel.group.FlxGroup();
		charPropGroup = new flixel.group.FlxGroup();
		animPropGroup.visible = false;
		add(animPropGroup);
		add(charPropGroup);

		propsTab = new SectionTab(px + 20, py + 15, tab.getWidth() - 40, 0.3, [{label: 'ANIM.PROP'}, {label: 'CHAR.PROP'}], camHud, (index) -> {
			animPropGroup.visible = index == 0;
			charPropGroup.visible = index == 1;
		});
		propsTab.cameras = [camHud];
		add(propsTab);
		propsTab.selectTab(1);

		buildCharProps(px, py + 75);
		buildAnimProps(px, py + 75);

		importErrorText = new flixel.text.FlxText(px + 10, py + 340, 270, '');
		importErrorText.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, flixel.util.FlxColor.RED, 'left');
		importErrorText.setBorderStyle(flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, flixel.util.FlxColor.BLACK, 1);
		importErrorText.scrollFactor.set(0, 0);
		importErrorText.visible = false;
		importErrorText.cameras = [camHud];
		add(importErrorText);
	}

	function label(group:flixel.group.FlxGroup, x:Float, y:Float, text:String):FlxText {
		var t = new FlxText(x, y, 0, text);
		t.setFormat(Paths.getPath('Funkin.otf', 'font'), 14, FlxColor.WHITE, 'left');
		t.cameras = [camHud];
		group.add(t);
		return t;
	}

	function stepper(group:flixel.group.FlxGroup, x:Float, y:Float, name:String, step:Float, onChange:Float->Void, decimals:Int = 0, min:Float = -99999,
			max:Float = 99999):NumberStepper {
		label(group, x, y, name);
		var s = new NumberStepper(x + 18, y, 0, step, camHud, onChange, decimals, min, max);
		s.cameras = [camHud];
		group.add(s);
		return s;
	}

	function buildCharProps(px:Float, y:Float) {
		final g = charPropGroup;
		final col1 = px + 20;
		final col2 = px + 130;
		final col3 = px + 245;

		label(g, col1, y, 'Files:');
		final importButton = new Button(col1, y + 20, 'Import', function() {
			core.api.FileDialog.open('Select a file to import.', 'Images|*.png|Atlas|*.xml;*.json', function(path) {
				importAsset(path);
				refreshCharProps();
			});
		}, camHud);
		importButton.cameras = [camHud];
		g.add(importButton);

		filesText = new FlxText(col1, y + 50, 160, '');
		filesText.setFormat(Paths.getPath('Funkin.otf', 'font'), 10, FlxColor.WHITE, 'left');
		filesText.cameras = [camHud];
		g.add(filesText);

		label(g, col2 + 60, y, 'Game Over:');
		final inputBg = new flixel.FlxSprite(col2 + 60, y + 20).loadGraphic(Paths.getPath('menus/editors/ui/inputText', 'image'));
		inputBg.scale.set(0.6, 0.6);
		inputBg.updateHitbox();
		inputBg.cameras = [camHud];
		g.add(inputBg);

		gameOverInput = new flixel.text.FlxInputText(inputBg.x + 4, inputBg.y + 1, inputBg.width - 8, '', 12, FlxColor.BLACK, FlxColor.TRANSPARENT);
		gameOverInput.cameras = [camHud];
		gameOverInput.onTextChange.add((text, _) -> setDeathCharacter(text));
		g.add(gameOverInput);

		final newGameOver = new ButtonPlus(col2 + 60, y + 44, 'New GameOver', function() {
			gameOverInput.text = '$curCharacter-dead';
			setDeathCharacter(gameOverInput.text);
		}, camHud);
		newGameOver.label.size = 14;
		newGameOver.label.y = newGameOver.y + (newGameOver.bg.height - newGameOver.label.height) / 2;
		newGameOver.cameras = [camHud];
		g.add(newGameOver);

		final rows = y + 95;
		label(g, col1, rows, 'Camera:');
		camX = stepper(g, col1, rows + 20, 'X:', 5, v -> setCameraOffset(0, v));
		camY = stepper(g, col1, rows + 42, 'Y:', 5, v -> setCameraOffset(1, v));

		label(g, col2, rows, 'Character:');
		charX = stepper(g, col2, rows + 20, 'X:', 5, v -> moveCharacter(v, char.y));
		charY = stepper(g, col2, rows + 42, 'Y:', 5, v -> moveCharacter(char.x, v));

		playableBox = new CheckBox(col3, rows, 'Playable', false, camHud, v -> {
			char.characterData.meta ??= {};
			char.characterData.meta.isPlayer = v;
			markChanged();
		});
		flipXBox = new CheckBox(col3, rows + 20, 'FlipX', false, camHud, v -> setFlip(v, flipYBox.checked));
		flipYBox = new CheckBox(col3, rows + 42, 'FlipY', false, camHud, v -> setFlip(flipXBox.checked, v));
		for (box in [playableBox, flipXBox, flipYBox]) {
			box.cameras = [camHud];
			g.add(box);
		}

		alphaStepper = stepper(g, col1, rows + 75, 'a:', 0.1, setAlpha, 1, 0, 1);
		sizeStepper = stepper(g, col2, rows + 75, 'Size:', 0.05, setSize, 2, 0.05, 10);
		sizeStepper.x += 18;

		final saveButton = new Button(col3 - 30, rows + 105, 'Save', saveCharacter, camHud);
		saveButton.cameras = [camHud];
		g.add(saveButton);
	}

	function buildAnimProps(px:Float, y:Float) {
		final g = animPropGroup;
		label(g, px + 20, y, 'Offset:');
		offsetX = stepper(g, px + 20, y + 20, 'X:', 1, v -> setAnimOffset(v, offsetY.value));
		offsetY = stepper(g, px + 20, y + 42, 'Y:', 1, v -> setAnimOffset(offsetX.value, v));

		label(g, px + 130, y, 'Animation:');
		fpsStepper = stepper(g, px + 130, y + 20, 'FPS:', 1, setAnimFramerate, 0, 1, 120);
		fpsStepper.x += 18;
		loopBox = new CheckBox(px + 130, y + 42, 'Loop', false, camHud, setAnimLooped);
		loopBox.cameras = [camHud];
		g.add(loopBox);

		label(g, px + 20, y + 80, 'Name:');
		animNameInput = input(g, px + 20, y + 100);
		animNameInput.onEnter.add(renameAnim);
		label(g, px + 20, y + 125, 'Prefix:');
		animPrefixInput = input(g, px + 20, y + 145);
		animPrefixInput.onEnter.add(setAnimPrefix);
		label(g, px + 180, y + 147, '(Enter to apply)').size = 10;
	}

	function input(group:flixel.group.FlxGroup, x:Float, y:Float):flixel.text.FlxInputText {
		final bg = new flixel.FlxSprite(x, y).loadGraphic(Paths.getPath('menus/editors/ui/inputText', 'image'));
		bg.scale.set(0.6, 0.6);
		bg.updateHitbox();
		bg.cameras = [camHud];
		group.add(bg);

		final field = new flixel.text.FlxInputText(x + 4, y + 1, bg.width - 8, '', 12, FlxColor.BLACK, FlxColor.TRANSPARENT);
		field.cameras = [camHud];
		group.add(field);
		return field;
	}

	function isTyping():Bool {
		for (field in [gameOverInput, animNameInput, animPrefixInput])
			if (field != null && field.hasFocus)
				return true;
		return false;
	}

	function selectedLayerData():Null<core.json.extensions.SpriteData.ObjectData>
		return char?.characterData?.render?.layers?.find(l -> l.name == selectedLayerName);

	// adds an empty anim to the selected layer, its prefix is set from ANIM.PROP -JloorDev
	function addNewAnim() {
		var layerData = selectedLayerData();
		if (layerData == null) {
			showImportError('Select a layer first');
			return;
		}
		layerData.anims ??= [];
		var name = 'newAnim';
		var n = 1;
		while (layerData.anims.exists(a -> a.name == name))
			name = 'newAnim${++n}';

		final data:core.json.extensions.SpriteData.AnimData = {name: name, prefix: '', framerate: 24, looped: false, offsets: [0, 0]};
		final owner = layerData;
		owner.anims.push(data);
		refreshAnimList(selectedLayerName, name);
		propsTab.selectTab(0);
		markChanged();

		pushAction({
			undo: () -> {
				owner.anims.remove(data);
				refreshAnimList(owner.name);
			},
			redo: () -> {
				owner.anims.push(data);
				refreshAnimList(owner.name, data.name);
			}
		});
	}

	function renameAnim(newName:String) {
		var data = animData(activeAnim);
		newName = StringTools.trim(newName);
		if (data == null || newName == '' || newName == activeAnim)
			return;
		if (selectedLayerData().anims.exists(a -> a.name == newName)) {
			showImportError('"$newName" already exists');
			return;
		}
		var offset = selectedLayer.offsets.get(activeAnim);
		data.name = newName;
		if (offset != null)
			selectedLayer.offsets.set(newName, offset);
		registerAnim(data);
		refreshAnimList(selectedLayerName, newName);
		markChanged();
	}

	function setAnimPrefix(prefix:String) {
		var data = animData(activeAnim);
		if (data == null)
			return;
		data.prefix = prefix;
		registerAnim(data);
		selectedLayer.playAnim(data.name, true);
		markChanged();
	}

	function registerAnim(data:core.json.extensions.SpriteData.AnimData) {
		if (data.prefix == null || data.prefix == '')
			return;
		try {
			selectedLayer.addAnim(data.name, data.prefix, data.framerate ?? 24, data.looped == true, data.indices);
		} catch (e:Dynamic) {
			showImportError('Prefix "${data.prefix}" not found');
		}
	}

	// fills the CHAR.PROP fields from the loaded character -JloorDev
	function refreshCharProps() {
		if (char == null || char.characterData == null || camX == null)
			return;
		var data = char.characterData;
		var cam = data.gameplay.cameraOffset ?? [0.0, 0.0];
		camX.setValue(cam[0]);
		camY.setValue(cam[1]);
		charX.setValue(char.x);
		charY.setValue(char.y);

		var first = data.render.layers.length > 0 ? data.render.layers[0] : null;
		alphaStepper.setValue(first?.alpha ?? 1.0);
		sizeStepper.setValue(first?.scale != null ? first.scale[0] : 1.0);
		playableBox.setChecked(data.meta?.isPlayer == true);
		flipXBox.setChecked(first?.flipX == true);
		flipYBox.setChecked(first?.flipY == true);

		gameOverInput.text = data.gameplay.death?.character ?? '';
		filesText.text = [for (i => l in data.render.layers) '${i + 1}. ${haxe.io.Path.withoutDirectory(l.path ?? l.name)}.png'].join('\n');
	}

	// the ANIM.PROP fields follow the selected anim, offsets also move with the arrow keys -JloorDev
	function refreshAnimProps() {
		if (offsetX == null || selectedLayer == null || activeAnim == '')
			return;
		var off = selectedLayer.offsets.get(activeAnim);
		offsetX.setValue(off?.x ?? 0);
		offsetY.setValue(off?.y ?? 0);

		var key = '$selectedLayerName|$activeAnim';
		if (key == animPropsKey)
			return;
		animPropsKey = key;
		var anim = selectedLayer.animation.getByName(activeAnim);
		var data = animData(activeAnim);
		fpsStepper.setValue(anim?.frameRate ?? data?.framerate ?? 24);
		loopBox.setChecked(anim?.looped ?? data?.looped == true);
		animNameInput.text = activeAnim;
		animPrefixInput.text = data?.prefix ?? '';
	}

	function markChanged() {
		advertency.visible = true;
	}

	function setCameraOffset(axis:Int, v:Float) {
		var data = char.characterData.gameplay;
		data.cameraOffset ??= [0, 0];
		data.cameraOffset[axis] = v;
		if (axis == 0)
			char.cameraOffset.x = v;
		else
			char.cameraOffset.y = v;
		markChanged();
	}

	// the layers keep their own position, they move along with the character -JloorDev
	function moveCharacter(x:Float, y:Float) {
		var dx = x - char.x;
		var dy = y - char.y;
		char.setPosition(x, y);
		for (layer in char.layers)
			layer.setPosition(layer.x + dx, layer.y + dy);
		markChanged();
	}

	function setFlip(x:Bool, y:Bool) {
		for (i => layer in char.layers) {
			layer.flipX = x;
			layer.flipY = y;
			if (i < char.characterData.render.layers.length) {
				char.characterData.render.layers[i].flipX = x;
				char.characterData.render.layers[i].flipY = y;
			}
		}
		markChanged();
	}

	function setAlpha(v:Float) {
		for (i => layer in char.layers) {
			layer.alpha = v;
			if (i < char.characterData.render.layers.length)
				char.characterData.render.layers[i].alpha = v;
		}
		markChanged();
	}

	function setSize(v:Float) {
		for (i => layer in char.layers) {
			layer.scale.set(v, v);
			if (i < char.characterData.render.layers.length)
				char.characterData.render.layers[i].scale = [v, v];
		}
		markChanged();
	}

	function setDeathCharacter(name:String) {
		var gameplay = char.characterData.gameplay;
		gameplay.death ??= {};
		gameplay.death.character = name != '' ? name : null;
		markChanged();
	}

	function setAnimOffset(x:Float, y:Float) {
		if (selectedLayer == null || activeAnim == '')
			return;
		var old = selectedLayer.offsets.get(activeAnim) ?? {x: 0.0, y: 0.0};
		final spr = selectedLayer;
		final anim = activeAnim;
		final fx = old.x;
		final fy = old.y;
		applyOffset(spr, anim, x, y);
		pushAction({
			undo: () -> applyOffset(spr, anim, fx, fy),
			redo: () -> applyOffset(spr, anim, x, y)
		});
	}

	function animData(name:String):Null<core.json.extensions.SpriteData.AnimData> {
		var layerData = char.characterData.render.layers.find(l -> l.name == selectedLayerName);
		return layerData?.anims?.find(a -> a.name == name);
	}

	function setAnimFramerate(v:Float) {
		var anim = selectedLayer?.animation.getByName(activeAnim);
		if (anim == null)
			return;
		anim.frameRate = v;
		var data = animData(activeAnim);
		if (data != null)
			data.framerate = Std.int(v);
		markChanged();
	}

	function setAnimLooped(v:Bool) {
		var anim = selectedLayer?.animation.getByName(activeAnim);
		if (anim == null)
			return;
		anim.looped = v;
		var data = animData(activeAnim);
		if (data != null)
			data.looped = v;
		selectedLayer.playAnim(activeAnim, true);
		markChanged();
	}

	function showImportError(msg:String) {
		if (importErrorText == null) {
			Console.log('[CharacterEditor] importErrorText is null! Error: $msg', true);
			return;
		}

		importErrorText.text = msg;
		importErrorText.visible = true;
		if (importErrorTimer != null)
			importErrorTimer.cancel();
		importErrorTimer = new flixel.util.FlxTimer().start(5.0, _ -> {
			if (importErrorText != null)
				importErrorText.visible = false;
		});
	}

	function getCharAssetDir():String {
		var base = modding.mods.ModsRegistry.onMod
			&& modding.mods.ModsRegistry.currentMod != '' ? '${core.assets.Library.modsFolder}/${modding.mods.ModsRegistry.currentMod}' : core.assets.Library.baseFolder;
		return '$base/images/game/characters/$curCharacter';
	}

	function importAsset(path:String) {
		if (path == null || path.length == 0)
			return;

		var ext = path.split('.').pop().toLowerCase();
		var baseName = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(path));

		var destDir = getCharAssetDir();
		if (!sys.FileSystem.exists(destDir)) {
			try {
				sys.FileSystem.createDirectory(destDir);
			} catch (e:Dynamic) {
				showImportError('Could not create asset folder:\n$destDir');
				Console.log('[CharacterEditor] createDirectory failed: $e', true);
				return;
			}
		}

		var sprite = new FunkinSprite(0, 0, true);
		var baseNoExt = path.substr(0, path.lastIndexOf('.'));

		var pngSrc:String = null;
		var atlasSrc:String = null;
		var atlasExt:String = null;

		switch (ext) {
			case 'png' | 'jpg' | 'jpeg':
				pngSrc = path;
				// Auto-detect companion atlas next to the PNG
				for (candidate in ['xml', 'json']) {
					var p = baseNoExt + '.' + candidate;
					if (sys.FileSystem.exists(p)) {
						atlasSrc = p;
						atlasExt = candidate;
						break;
					}
				}

			case 'xml' | 'json':
				atlasSrc = path;
				atlasExt = ext;
				pngSrc = baseNoExt + '.png';
				if (!sys.FileSystem.exists(pngSrc)) {
					showImportError('PNG not found:\n$baseName.png\n(put it next to the .$ext)');
					Console.log('[CharacterEditor] PNG not found: $pngSrc', true);
					return;
				}

			default:
				showImportError('Unsupported format: .$ext');
				Console.log('[CharacterEditor] Unsupported: $ext', true);
				return;
		}

		// Copy PNG to dest
		var destPng = '$destDir/$baseName.png';
		if (!sys.FileSystem.exists(destPng))
			sys.io.File.copy(pngSrc, destPng);

		if (atlasSrc != null) {
			var destAtlas = '$destDir/$baseName.$atlasExt';
			if (!sys.FileSystem.exists(destAtlas))
				sys.io.File.copy(atlasSrc, destAtlas);

			// a json that isn't a TexturePacker sheet (an Animate atlas) throws while parsing -JloorDev
			var frames = null;
			try {
				frames = atlasExt == 'xml' ? flixel.graphics.frames.FlxAtlasFrames.fromSparrow(destPng,
					destAtlas) : flixel.graphics.frames.FlxAtlasFrames.fromTexturePackerJson(destPng, destAtlas);
			} catch (e:Dynamic) {
				Console.log('[CharacterEditor] could not parse $atlasSrc: $e', true);
			}
			if (frames == null) {
				showImportError('Failed to parse atlas:\n$baseName.$atlasExt');
				Console.log('[CharacterEditor] frames null for: $atlasSrc', true);
				return;
			}
			sprite.frames = frames;
		} else {
			var bmp = openfl.display.BitmapData.fromFile(destPng);
			if (bmp == null) {
				showImportError('Failed to load:\n$baseName.png');
				return;
			}
			sprite.loadGraphic(flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, destPng));
		}

		var layerName = 'imported_' + importedLayers.length;
		var layerPath = '$curCharacter/$baseName';

		sprite.setPosition(char.x, char.y);

		char.layers.push(sprite);
		char.layerMap.set(layerName, sprite);
		char.characterData.render.layers.push({
			name: layerName,
			path: layerPath,
			position: [char.x, char.y],
			anims: []
		});

		add(sprite);

		importedLayers.push({sprite: sprite, name: layerName, path: layerPath});

		advertency.visible = true;

		refreshLayerList();

		final addedSprite = sprite;
		final addedName = layerName;
		final addedData = char.characterData.render.layers[char.characterData.render.layers.length - 1];
		final addedEntry = importedLayers[importedLayers.length - 1];

		pushAction({
			undo: () -> {
				remove(addedSprite, true);
				char.layers.splice(char.layers.indexOf(addedSprite), 1);
				char.layerMap.remove(addedName);
				char.characterData.render.layers.splice(char.characterData.render.layers.indexOf(addedData), 1);
				importedLayers = importedLayers.filter(l -> l.name != addedName);
				if (selectedLayerName == addedName) {
					selectedLayer = null;
					selectedLayerName = '';
					activeAnim = '';
				}
				refreshLayerList();
			},
			redo: () -> {
				char.layers.push(addedSprite);
				char.layerMap.set(addedName, addedSprite);
				char.characterData.render.layers.push(addedData);
				importedLayers.push(addedEntry);
				add(addedSprite);
				refreshLayerList();
			}
		});

		Console.log('[CharacterEditor] Layer added: $layerName');
	}

	function refreshAnimList(layerName:String, ?select:String) {
		for (btn in animButtons) {
			remove(btn);
			btn.destroy();
		}
		animButtons = [];

		var layerData = char.characterData.render.layers.find(l -> l.name == layerName);
		if (layerData == null || layerData.anims == null)
			return;

		for (i in 0...layerData.anims.length) {
			var name = layerData.anims[i].name;
			var btn = createAnimButton(20, 180 + i * 40, name);
			btn.scrollFactor.set(0, 0);
			btn.cameras = [camHud];
			animButtons.push(btn);
			tabAnimGroup.add(btn);
		}

		if (layerData.anims.length > 0) {
			activeAnim = select != null && layerData.anims.exists(a -> a.name == select) ? select : layerData.anims[0].name;
			char.playAnim(activeAnim, true);
		} else {
			activeAnim = '';
		}
	}

	function createAnimButton(x:Float, y:Float, name:String):StatsButton {
		var btn:StatsButton = null;
		btn = new StatsButton(x, y, name, null, camHud, null, null, function() {
			ghostChar.playAnim(btn.label.text, true);
			ghostChar.visible = btn.isVisibleHit;
		});
		btn.scrollFactor.set(0, 0);
		btn.cameras = [camHud];
		return btn;
	}

	function placeRow(btn:flixel.FlxSprite, index:Int, height:Float = 32) {
		var y = LIST_TOP + index * ROW - listScroll;
		if (Std.isOfType(btn, StatsButton))
			cast(btn, StatsButton).setBaseY(y);
		else
			btn.y = y;
		btn.visible = y >= LIST_TOP - 4 && y + height <= LIST_BOTTOM + 4;
	}

	function layoutLists() {
		var onAnims = tabAnimGroup.visible;
		var rows = onAnims ? animButtons.length + 1 : layerButtons.length;
		var maxScroll = Math.max(0, rows * ROW - (LIST_BOTTOM - LIST_TOP));
		listScroll = FlxMath.bound(listScroll, 0, maxScroll);

		var trackH = LIST_BOTTOM - LIST_TOP;
		var thumbH = Math.max(30, trackH * trackH / (rows * ROW));
		var m = FlxG.mouse.getViewPosition(camHud);
		if (FlxG.mouse.justPressed && maxScroll > 0 && scrollTrack.overlapsPoint(m, true, camHud))
			draggingThumb = true;
		if (!FlxG.mouse.pressed)
			draggingThumb = false;
		if (draggingThumb)
			listScroll = FlxMath.bound((m.y - LIST_TOP - thumbH / 2) / (trackH - thumbH), 0, 1) * maxScroll;

		for (i => btn in animButtons)
			placeRow(btn, i);
		for (i => btn in layerButtons)
			placeRow(btn, i);
		if (newAnimButton != null)
			placeRow(newAnimButton, animButtons.length, newAnimButton.height);

		scrollTrack.visible = scrollThumb.visible = maxScroll > 0;
		scrollThumb.setGraphicSize(scrollThumb.frameWidth, thumbH);
		scrollThumb.updateHitbox();
		scrollThumb.y = LIST_TOP + (maxScroll > 0 ? listScroll / maxScroll : 0) * (trackH - thumbH);
	}

	function refreshLayerList() {
		for (btn in layerButtons) {
			flixel.tweens.FlxTween.cancelTweensOf(btn);
			tabLayersGroup.remove(btn);
			btn.destroy();
		}
		layerButtons = [];

		if (char == null || char.characterData == null)
			return;

		var total = char.characterData.render.layers.length;

		for (i in 0...total) {
			var name = char.characterData.render.layers[i].name;
			var capturedIndex = i;

			var btn = new StatsButton(20, 180 + i * 40, name, null, camHud, function(newIndex:Int) {
				reorderLayer(capturedIndex, newIndex);
			}, function() {
				var sprite = char.layers[capturedIndex];
				var layerName = char.characterData.render.layers[capturedIndex].name;
				var layerData = char.characterData.render.layers[capturedIndex];
				var importedEntry = importedLayers.filter(l -> l.name == layerName)[0];

				final capturedSprite = sprite;
				final capturedName = layerName;
				final capturedData = layerData;
				final capturedEntry = importedEntry;

				remove(capturedSprite, true);
				char.layers.splice(char.layers.indexOf(capturedSprite), 1);
				char.layerMap.remove(capturedName);
				char.characterData.render.layers.splice(char.characterData.render.layers.indexOf(capturedData), 1);
				importedLayers = importedLayers.filter(l -> l.name != capturedName);
				if (selectedLayerName == capturedName) {
					selectedLayer = null;
					selectedLayerName = '';
					activeAnim = '';
				}
				advertency.visible = true;
				refreshLayerList();

				pushAction({
					undo: () -> {
						var restoreIndex = Std.int(Math.min(capturedIndex, char.layers.length));
						char.layers.insert(restoreIndex, capturedSprite);
						char.layerMap.set(capturedName, capturedSprite);
						char.characterData.render.layers.insert(restoreIndex, capturedData);
						if (capturedEntry != null)
							importedLayers.push(capturedEntry);
						add(capturedSprite);
						refreshLayerList();
					},
					redo: () -> {
						remove(capturedSprite, true);
						char.layers.splice(char.layers.indexOf(capturedSprite), 1);
						char.layerMap.remove(capturedName);
						char.characterData.render.layers.splice(char.characterData.render.layers.indexOf(capturedData), 1);
						importedLayers = importedLayers.filter(l -> l.name != capturedName);
						if (selectedLayerName == capturedName) {
							selectedLayer = null;
							selectedLayerName = '';
							activeAnim = '';
						}
						refreshLayerList();
					}
				});
			});
			btn.setDragContext(i, total, 40);
			btn.scrollFactor.set(0, 0);
			btn.cameras = [camHud];
			layerButtons.push(btn);
			tabLayersGroup.add(btn);
		}
	}

	function reorderLayer(fromIndex:Int, toIndex:Int) {
		if (fromIndex == toIndex)
			return;

		var layerData = char.characterData.render.layers.splice(fromIndex, 1)[0];
		char.characterData.render.layers.insert(toIndex, layerData);

		var sprite = char.layers.splice(fromIndex, 1)[0];
		char.layers.insert(toIndex, sprite);

		for (layer in char.layers)
			remove(layer, true);
		for (layer in char.layers)
			add(layer);

		advertency.visible = true;
		refreshLayerList();

		final from = fromIndex;
		final to = toIndex;
		pushAction({
			undo: () -> {
				var ld = char.characterData.render.layers.splice(to, 1)[0];
				char.characterData.render.layers.insert(from, ld);
				var spr = char.layers.splice(to, 1)[0];
				char.layers.insert(from, spr);
				for (layer in char.layers)
					remove(layer, true);
				for (layer in char.layers)
					add(layer);
				refreshLayerList();
			},
			redo: () -> {
				var ld = char.characterData.render.layers.splice(from, 1)[0];
				char.characterData.render.layers.insert(to, ld);
				var spr = char.layers.splice(from, 1)[0];
				char.layers.insert(to, spr);
				for (layer in char.layers)
					remove(layer, true);
				for (layer in char.layers)
					add(layer);
				refreshLayerList();
			}
		});
	}

	function getLayerUnderMouse():Null<{name:String, sprite:FunkinSprite}> {
		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;
		for (name => sprite in char.layerMap) {
			if (mx >= sprite.x && mx <= sprite.x + sprite.width && my >= sprite.y && my <= sprite.y + sprite.height)
				return {name: name, sprite: sprite};
		}
		return null;
	}

	function movementMouse(?hit:{name:String, sprite:FunkinSprite}) {
		if (char == null)
			return;

		var panelX = FlxG.mouse.getViewPosition(camHud).x;
		if (FlxG.mouse.justPressed && (panelX >= FlxG.width * 0.72 || panelX <= 300))
			return;

		if (FlxG.mouse.justPressed) {
			var mousePos = FlxG.mouse.getWorldPosition(camEditor);
			var anyLayerDragging = false;
			for (btn in layerButtons)
				if (btn.dragging) {
					anyLayerDragging = true;
					break;
				}

			if (anyLayerDragging)
				return;

			if (hit != null) {
				selectedLayer = hit.sprite;
				selectedLayerName = hit.name;
				isDragging = true;
				dragStartX = selectedLayer.x;
				dragStartY = selectedLayer.y;
				dragOffsetX = mousePos.x - selectedLayer.x;
				dragOffsetY = mousePos.y - selectedLayer.y;
				refreshAnimList(selectedLayerName);
			} else {
				selectedLayer = null;
				selectedLayerName = '';
				isDragging = false;
				isCamDragging = true;
			}
		}

		if (FlxG.mouse.justReleased) {
			if (isDragging && selectedLayer != null) {
				for (i in 0...char.layers.length) {
					if (char.layers[i] == selectedLayer) {
						char.characterData.render.layers[i].position = [selectedLayer.x - char.x, selectedLayer.y - char.y];
						break;
					}
				}

				if (selectedLayer.x != dragStartX || selectedLayer.y != dragStartY) {
					final spr = selectedLayer;
					final fx = dragStartX;
					final fy = dragStartY;
					final tx = spr.x;
					final ty = spr.y;
					pushAction({
						undo: () -> spr.setPosition(fx, fy),
						redo: () -> spr.setPosition(tx, ty)
					});
				}
			}
			isDragging = false;
			isCamDragging = false;
		}

		if (isDragging && selectedLayer != null) {
			var mousePos = FlxG.mouse.getWorldPosition(camEditor);
			selectedLayer.x = mousePos.x - dragOffsetX;
			selectedLayer.y = mousePos.y - dragOffsetY;
		}

		if (isCamDragging && FlxG.mouse.pressed) {
			var anyLayerDragging = false;
			for (btn in layerButtons)
				if (btn.dragging) {
					anyLayerDragging = true;
					break;
				}
			if (anyLayerDragging) {
				isCamDragging = false;
				return;
			}

			camEditor.scroll.x -= (FlxG.mouse.deltaViewX / camEditor.zoom) * 0.5;
			camEditor.scroll.y -= (FlxG.mouse.deltaViewY / camEditor.zoom) * 0.5;
			camEditor.scroll.x = Math.max(-(FlxG.width * 2), Math.min(FlxG.width * 2, camEditor.scroll.x));
			camEditor.scroll.y = Math.max(-(FlxG.height * 2), Math.min(FlxG.height * 2, camEditor.scroll.y));
		}
	}

	function selectionAnims() {
		var mouseScreen = FlxG.mouse.getViewPosition(camHud);
		var mx = mouseScreen.x;
		var my = mouseScreen.y;

		for (btn in animButtons) {
			var isHover = btn.visible && mx >= btn.x && mx <= btn.x + btn.width && my >= btn.y && my <= btn.y + btn.height;
			var isActive = btn.label.text == activeAnim;

			if (isHover && FlxG.mouse.justPressed) {
				activeAnim = btn.label.text;
				char.playAnim(btn.label.text, true);

				for (layerData in char.characterData.render.layers) {
					if (layerData.anims == null)
						continue;
					for (anim in layerData.anims) {
						if (anim.name == btn.label.text) {
							var sprite = char.layerMap.get(layerData.name);
							if (sprite != null) {
								selectedLayer = sprite;
								selectedLayerName = layerData.name;
							}
							break;
						}
					}
				}
			}

			btn.label.color = (isHover || isActive) ? FlxColor.YELLOW : 0xAAFFFFFF;
		}
	}

	function selectionLayers() {
		var mouseScreen = FlxG.mouse.getViewPosition(camHud);
		var mx = mouseScreen.x;
		var my = mouseScreen.y;

		for (btn in layerButtons) {
			var isHover = btn.visible && mx >= btn.x && mx <= btn.x + btn.width && my >= btn.y && my <= btn.y + btn.height;
			var isActive = btn.label.text == selectedLayerName;

			if (isHover && FlxG.mouse.justPressed) {
				selectedLayerName = btn.label.text;
				selectedLayer = char.layerMap.get(selectedLayerName);
				refreshAnimList(selectedLayerName);
			}

			btn.label.color = (isHover || isActive) ? FlxColor.YELLOW : 0xAAFFFFFF;
		}
	}

	function centerCameraOnChar() {
		if (char == null)
			return;

		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;

		for (layer in char.layers) {
			if (minX > layer.x)
				minX = layer.x;
			if (minY > layer.y)
				minY = layer.y;
			if (maxX < layer.x + layer.width)
				maxX = layer.x + layer.width;
			if (maxY < layer.y + layer.height)
				maxY = layer.y + layer.height;
		}

		if (minX == Math.POSITIVE_INFINITY) {
			minX = char.x;
			minY = char.y;
			maxX = char.x + char.width;
			maxY = char.y + char.height;
		}

		var centerX = (minX + maxX) / 2;
		var centerY = (minY + maxY) / 2;

		camEditor.scroll.x = centerX - FlxG.width / 2;
		camEditor.scroll.y = centerY - FlxG.height / 2;
	}

	function saveCharacter() {
		if (char == null)
			return;

		char.characterData.gameplay.position = [char.x, char.y];

		for (i in 0...char.layers.length) {
			if (i >= char.characterData.render.layers.length)
				break;
			char.characterData.render.layers[i].position = [char.layers[i].x - char.x, char.layers[i].y - char.y];
		}

		for (layerData in char.characterData.render.layers) {
			if (layerData.anims == null)
				continue;
			var sprite = char.layerMap.get(layerData.name);
			if (sprite == null)
				continue;
			for (anim in layerData.anims) {
				var offset = sprite.offsets.get(anim.name);
				if (offset != null)
					anim.offsets = [offset.x, offset.y];
			}
		}

		var path = Paths.getPath('data/game/characters/$curCharacter', 'json');
		var json = haxe.Json.stringify(char.characterData, null, '\t');
		sys.io.File.saveContent(path, json);

		Console.log('[CharacterEditor] Saved: $path');
		if (SaveData.data.flashingLights)
			FlxG.camera.flash(FlxColor.WHITE, 0.3);

		savedUndoLength = undoStack.length;
		updateAdvertency();
	}

	function adjustOffsets() {
		var anyKey = Controls.UI_LEFT || Controls.UI_RIGHT || Controls.UI_UP || Controls.UI_DOWN;

		if (selectedLayer != null && activeAnim != '') {
			var offset = selectedLayer.offsets.get(activeAnim) ?? {x: 0.0, y: 0.0};
			var step = FlxG.keys.pressed.SHIFT ? 10.0 : 1.0;

			if (anyKey && !offsetEditing) {
				offsetEditing = true;
				offsetStartX = offset.x;
				offsetStartY = offset.y;
			}

			if (Controls.UI_LEFT) {
				offset.x -= step;
				selectedLayer.offsets.set(activeAnim, offset);
			}
			if (Controls.UI_RIGHT) {
				offset.x += step;
				selectedLayer.offsets.set(activeAnim, offset);
			}
			if (Controls.UI_UP) {
				offset.y -= step;
				selectedLayer.offsets.set(activeAnim, offset);
			}
			if (Controls.UI_DOWN) {
				offset.y += step;
				selectedLayer.offsets.set(activeAnim, offset);
			}

			if (anyKey)
				selectedLayer.playAnim(activeAnim, false);

			if (!anyKey && offsetEditing) {
				offsetEditing = false;
				if (offset.x != offsetStartX || offset.y != offsetStartY) {
					final spr = selectedLayer;
					final anim = activeAnim;
					final fx = offsetStartX;
					final fy = offsetStartY;
					final tx = offset.x;
					final ty = offset.y;
					pushAction({
						undo: () -> applyOffset(spr, anim, fx, fy),
						redo: () -> applyOffset(spr, anim, tx, ty)
					});
				}
			}
		} else if (!anyKey) {
			offsetEditing = false;
		}
	}

	function applyOffset(spr:FunkinSprite, anim:String, x:Float, y:Float) {
		spr.offsets.set(anim, {x: x, y: y});
		if (anim == activeAnim)
			spr.playAnim(anim, false);
	}

	function infoOffsetsandFramerate() {
		if (char != null) {
			var tx = selectedLayer != null ? selectedLayer.x : char.x;
			var ty = selectedLayer != null ? selectedLayer.y : char.y;
			var name = selectedLayer != null ? selectedLayerName : 'char';
			info.text = '$name x: ${FlxMath.roundDecimal(tx, 2)}\n$name y: ${FlxMath.roundDecimal(ty, 2)}';

			if (selectedLayer != null) {
				var curAnim = selectedLayer.animation.curAnim;
				var frameIndex = curAnim != null ? curAnim.curFrame + 1 : 0;
				var totalFrames = curAnim != null ? curAnim.numFrames : 0;

				var offset = selectedLayer.offsets.get(activeAnim);
				var ox = offset != null ? offset.x : 0.0;
				var oy = offset != null ? offset.y : 0.0;

				infoAnim.text = '$activeAnim [$frameIndex/$totalFrames]\nOffset: [${FlxMath.roundDecimal(ox, 1)}, ${FlxMath.roundDecimal(oy, 1)}]';
			}
		}
	}

	// drags
	function pushAction(action:EditorAction) {
		undoStack.push(action);
		redoStack = [];
		updateAdvertency();

		if (undoStack.length > 100)
			undoStack.shift();
	}

	function undo() {
		if (undoStack.length == 0)
			return;
		var action = undoStack.pop();
		action.undo();
		redoStack.push(action);
		updateAdvertency();
	}

	function redo() {
		if (redoStack.length == 0)
			return;
		var action = redoStack.pop();
		action.redo();
		undoStack.push(action);
		updateAdvertency();
	}

	function updateAdvertency() {
		advertency.visible = (undoStack.length != savedUndoLength);
	}

	function clearHistory() {
		undoStack = [];
		redoStack = [];
		savedUndoLength = 0;
		if (advertency != null)
			advertency.visible = false;
	}

	function handleUndoRedo() {
		if (!FlxG.keys.pressed.CONTROL)
			return;

		if (FlxG.keys.justPressed.Z) {
			if (FlxG.keys.pressed.SHIFT)
				redo();
			else
				undo();
		}

		if (FlxG.keys.justPressed.Y)
			redo();
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		infoOffsetsandFramerate();

		var hit = getLayerUnderMouse();

		if (!keysLocked && (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.WINDOWS) && FlxG.keys.justPressed.S) {
			saveCharacter();
		}

		var typing = isTyping();

		movementMouse(hit);

		sectionTab.handleInput();
		propsTab.handleInput();
		refreshAnimProps();

		handleUndoRedo();

		if (!typing && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.WINDOWS)
			adjustOffsets();

		selectionAnims();
		selectionLayers();

		selectionObj.trackSprite(selectedLayer);

		if (hit != null) {
			hoverText.text = hit.name;
			var mouseScreen = FlxG.mouse.getViewPosition(camHud);
			hoverText.x = mouseScreen.x + 20;
			hoverText.y = mouseScreen.y + 26;
			hoverText.visible = true;
		} else {
			hoverText.visible = false;
		}

		if (FlxG.mouse.wheel != 0) {
			if (FlxG.mouse.getViewPosition(camHud).x <= 300)
				listScroll -= FlxG.mouse.wheel * ROW;
			else
				camEditor.zoom = Math.max(0.25, Math.min(3.0, camEditor.zoom + (FlxG.mouse.wheel > 0 ? 0.1 : -0.1)));
		}
		layoutLists();

		if (!typing && Controls.BACK) {
			keysLocked = true;
			MusicBeatState.switchState(() -> new DebugMenu());
		}
	}

	override public function destroy():Void {
		if (importErrorTimer != null) {
			importErrorTimer.cancel();
			importErrorTimer.destroy();
			importErrorTimer = null;
		}

		flixel.tweens.FlxTween.cancelTweensOf(this);

		if (char != null) {
			for (layer in char.layers) {
				flixel.tweens.FlxTween.cancelTweensOf(layer);
				remove(layer, true);
				layer.destroy();
			}
			remove(char, true);
			char.destroy();
			char = null;
		}

		for (imported in importedLayers) {
			if (imported.sprite != null) {
				flixel.tweens.FlxTween.cancelTweensOf(imported.sprite);
				remove(imported.sprite, true);
				imported.sprite.destroy();
			}
		}
		importedLayers = null;

		for (btn in animButtons) {
			flixel.tweens.FlxTween.cancelTweensOf(btn);
			btn.destroy();
		}
		animButtons = null;

		for (btn in layerButtons) {
			flixel.tweens.FlxTween.cancelTweensOf(btn);
			btn.destroy();
		}
		layerButtons = null;

		clearHistory();

		selectedLayer = null;
		selectionObj = null;

		if (camHud != null) {
			FlxG.cameras.remove(camHud, false);
			camHud = null;
		}
		if (core.ui.FPSCounter.instance != null)
			core.ui.FPSCounter.instance.updateVisibility();
		super.destroy();
	}
}

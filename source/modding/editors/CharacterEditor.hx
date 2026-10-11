package modding.editors;

import game.objects.Camera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import core.assets.FunkinSprite;
import game.objects.sprites.Character;
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

	// camera on camera Editor
	var isCamDragging:Bool = false;

	// character
	var info:FlxText;
	var animButtons:Array<FlxText> = [];

	var selectedLayer:FunkinSprite = null;
	var selectedLayerName:String = '';
	var activeAnim:String = '';
	var importedLayers:Array<{sprite:FunkinSprite, name:String, path:String}> = [];

	public var char:Character = null;
	public var curCharacter:String = 'bf';

	public function new(curCharacter:String) {
		super();
		this.curCharacter = curCharacter;
	}

	function createCameras() {
		camEditor = new Camera();
		camHud = new Camera();
		camHud.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHud, false);
	}

	override public function create() {
		super.create();

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/artistic-expression/artistic-expression', 'music'), 0.6, 137);

		createCameras();

		final tile = FlxGridOverlay.createGrid(32, 32, FlxG.width * 5, FlxG.height * 5, true, 0xFF2C2C2C, 0xFF1F1F1F);
		final grid = new flixel.FlxSprite(-(FlxG.width * 5) * 0.32, -(FlxG.height * 5) * 0.3);
		grid.loadGraphic(tile);
		grid.scrollFactor.set(0, 0);
		add(grid);

		char = loadCharacter('idk', curCharacter, 0, 0);

		centerCameraOnChar();

		createHUD();

		FlxG.cameras.remove(camHud, false);
		FlxG.cameras.add(camHud, false);
	}

	function loadCharacter(id:String, name:String, x:Float, y:Float):Character {
		var char = new Character(id, name, x, y);
		if (char == null)
			return null;
		char.editorMode = true;
		for (layer in char.layers)
			add(layer);
		return char;
	}

	function createHUD() {
		// animations
		tabLeft();

		hoverText = new FlxText(0, 0, 0, '');
		hoverText.setFormat(null, 14, FlxColor.YELLOW, 'left');
		hoverText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		hoverText.scrollFactor.set(0, 0);
		hoverText.cameras = [camHud];
		add(hoverText);

		tabRight();

		var path = Paths.getPath('data/characters');
		var chars:Array<String> = [];
		if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path)) {
			chars = sys.FileSystem.readDirectory(path).map(function(file) {
				return StringTools.replace(file, '.json', '');
			});
		} else
			Console.log('Chars data not loading in list');

		final dd2 = new DropDown(0, 30, curCharacter, chars, function(selected) {
			if (char == null)
				return;
			char.destroy();
			curCharacter = selected;
			char = loadCharacter('idk', selected, 0, 0);

			if (char.characterData != null
				&& char.characterData.render != null
				&& char.characterData.render.layers != null
				&& char.characterData.render.layers.length > 0) {
				refreshAnimList(char.characterData.render.layers[0].name);
			}

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
	}

	function tabLeft() {
		final tab2 = new Tab(10, 20, 'Símbolo 10');
		tab2.cameras = [camHud];
		add(tab2);

		info = new FlxText(30, 40, FlxG.width, "char x: " + "\nchar y: ");
		info.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFFFFFFFF, 'left');
		info.scrollFactor.set(0, 0);
		info.cameras = [camHud];
		add(info);

		if (char != null
			&& char.characterData != null
			&& char.characterData.render != null
			&& char.characterData.render.layers != null
			&& char.characterData.render.layers.length > 0) {
			refreshAnimList(char.characterData.render.layers[0].name);
		}
	}

	function tabRight() {
		final tab = new Tab(FlxG.width * 0.72, 20, 'Símbolo 9');
		tab.cameras = [camHud];
		add(tab);

		final importButton = new Button(0, 0, 'Import', function() {
			core.api.FileDialog.open('Select a file to import.', 'Images|*.png|Atlas|*.xml;*.json', function(path) {
				importAsset(path);
			});
		}, camHud);
		importButton.cameras = [camHud];
		add(importButton);
		tab.addItem(importButton, 20, 80);

		final saveButton = new Button(0, 0, 'Save', function() {
			saveCharacter();
		}, camHud);
		saveButton.cameras = [camHud];
		add(saveButton);
		tab.addItem(saveButton, 20, 120);
	}

	function importAsset(path:String) {
		if (path == null || path.length == 0)
			return;

		var ext = path.split('.').pop().toLowerCase();
		var sprite = new FunkinSprite(0, 0, true);

		switch (ext) {
			case 'png' | 'jpg' | 'jpeg':
				var bmp = openfl.display.BitmapData.fromFile(path);
				if (bmp == null)
					return;
				var graphic = flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, path);
				sprite.loadGraphic(graphic);

			case 'xml' | 'json':
				var pngPath = path.substr(0, path.lastIndexOf('.')) + '.png';
				if (!sys.FileSystem.exists(pngPath)) {
					Console.log('[CharacterEditor] PNG not found: $pngPath', true);
					return;
				}
				var frames = ext == 'xml' ? flixel.graphics.frames.FlxAtlasFrames.fromSparrow(pngPath,
					path) : flixel.graphics.frames.FlxAtlasFrames.fromTexturePackerJson(pngPath, path);
				if (frames == null)
					return;
				sprite.frames = frames;

			default:
				Console.log('[CharacterEditor] Unsupported: $ext', true);
				return;
		}

		var layerName = 'imported_' + importedLayers.length;

		sprite.setPosition(char.x, char.y);

		char.layers.push(sprite);
		char.layerMap.set(layerName, sprite);
		char.characterData.render.layers.push({
			name: layerName,
			path: path,
			position: [char.x, char.y],
			anims: []
		});

		add(sprite);

		importedLayers.push({sprite: sprite, name: layerName, path: path});

		Console.log('[CharacterEditor] Layer added: $layerName');
	}

	function refreshAnimList(layerName:String) {
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
			var btn = new FlxText(30, 100 + i * 32, 190, name);
			btn.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xAAFFFFFF, 'left');
			btn.scrollFactor.set(0, 0);
			btn.cameras = [camHud];
			animButtons.push(btn);
			add(btn);
		}

		if (layerData.anims.length > 0) {
			activeAnim = layerData.anims[0].name;
			char.playAnim(activeAnim, true);
		} else {
			activeAnim = '';
		}
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

		if (FlxG.mouse.justPressed) {
			var mousePos = FlxG.mouse.getWorldPosition(camEditor);

			if (hit != null) {
				if (selectedLayer != null)
					selectedLayer.color = FlxColor.WHITE;
				selectedLayer = hit.sprite;
				selectedLayerName = hit.name;
				selectedLayer.color = FlxColor.YELLOW;
				isDragging = true;
				dragOffsetX = mousePos.x - selectedLayer.x;
				dragOffsetY = mousePos.y - selectedLayer.y;
				refreshAnimList(selectedLayerName);
			} else {
				if (selectedLayer != null)
					selectedLayer.color = FlxColor.WHITE;
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
			var isHover = mx >= btn.x && mx <= btn.x + btn.width && my >= btn.y && my <= btn.y + btn.height;
			var isActive = btn.text == activeAnim;

			if (isHover && FlxG.mouse.justPressed) {
				activeAnim = btn.text;
				char.playAnim(btn.text, true);
			}

			btn.color = (isHover || isActive) ? FlxColor.YELLOW : 0xAAFFFFFF;
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

		for (i in 0...char.layers.length) {
			if (i >= char.characterData.render.layers.length)
				break;
			char.characterData.render.layers[i].position = [char.layers[i].x - char.x, char.layers[i].y - char.y];
		}

		var path = Paths.getPath('data/characters/$curCharacter', 'json');
		var json = haxe.Json.stringify(char.characterData, null, '\t');
		sys.io.File.saveContent(path, json);

		Console.log('[CharacterEditor] Saved: $path');
		FlxG.camera.flash(FlxColor.WHITE, 0.3);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (char != null) {
			var tx = selectedLayer != null ? selectedLayer.x : char.x;
			var ty = selectedLayer != null ? selectedLayer.y : char.y;
			var name = selectedLayer != null ? selectedLayerName : 'char';
			info.text = '$name x: ${flixel.math.FlxMath.roundDecimal(tx, 2)}\n$name y: ${flixel.math.FlxMath.roundDecimal(ty, 2)}';
		}

		var hit = getLayerUnderMouse();

		movementMouse(hit);

		selectionAnims();

		if (hit != null) {
			hoverText.text = hit.name;
			var mouseScreen = FlxG.mouse.getViewPosition(camHud);
			hoverText.x = mouseScreen.x + 20;
			hoverText.y = mouseScreen.y + 26;
			hoverText.visible = true;
		} else {
			hoverText.visible = false;
		}

		if (FlxG.mouse.wheel != 0)
			camEditor.zoom = Math.max(0.25, Math.min(3.0, camEditor.zoom + (FlxG.mouse.wheel > 0 ? 0.1 : -0.1)));

		if (Controls.BACK)
			MusicBeatState.switchState(() -> new DebugMenu());
	}
}

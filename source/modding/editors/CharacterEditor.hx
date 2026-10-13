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
	public var curCharacter:String = 'bf';

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

		core.rhythm.audio.MasterAudio.playMenu(Paths.getPath('menus/artistic-expression/artistic-expression', 'music'), 0.6, 137);

		createCameras();

		final tile = FlxGridOverlay.createGrid(32, 32, FlxG.width * 5, FlxG.height * 5, true, 0xFF2C2C2C, 0xFF1F1F1F);
		final grid = new flixel.FlxSprite(-(FlxG.width * 5) * 0.32, -(FlxG.height * 5) * 0.3);
		grid.loadGraphic(tile);
		grid.scrollFactor.set(0, 0);
		add(grid);

		selectionObj = new SelectionObj();
		add(selectionObj);

		createHUD();

		char = loadCharacter('idk', curCharacter, 0, 0);

		centerCameraOnChar();

		if (char.characterData != null
			&& char.characterData.render != null
			&& char.characterData.render.layers != null
			&& char.characterData.render.layers.length > 0) {
			refreshAnimList(char.characterData.render.layers[0].name);
			refreshLayerList();
		}

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

		add(sectionTab);

		tabLayersGroup.visible = false;

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
			curCharacter = chars[0];
		} else
			Console.log('Chars data not loading in list');

		final dd2 = new DropDown(0, 30, curCharacter, chars, function(selected) {
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
			char = loadCharacter('idk', selected, 0, 0);

			if (char.characterData != null
				&& char.characterData.render != null
				&& char.characterData.render.layers != null
				&& char.characterData.render.layers.length > 0) {
				refreshAnimList(char.characterData.render.layers[0].name);
				refreshLayerList();
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

		advertency = new FlxText(20, FlxG.height * 0.9, 0, 'Unsaved Changes! - Dont forget to click the save button.');
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

		importErrorText = new flixel.text.FlxText(FlxG.width * 0.72 + 10, 185, 270, '');
		importErrorText.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, flixel.util.FlxColor.RED, 'left');
		importErrorText.setBorderStyle(flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, flixel.util.FlxColor.BLACK, 1);
		importErrorText.scrollFactor.set(0, 0);
		importErrorText.visible = false;
		importErrorText.cameras = [camHud];
		add(importErrorText);
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

			var frames = atlasExt == 'xml' ? flixel.graphics.frames.FlxAtlasFrames.fromSparrow(destPng,
				destAtlas) : flixel.graphics.frames.FlxAtlasFrames.fromTexturePackerJson(destPng, destAtlas);
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
			var btn = new StatsButton(20, 180 + i * 40, name, null, camHud);
			btn.scrollFactor.set(0, 0);
			btn.cameras = [camHud];
			animButtons.push(btn);
			tabAnimGroup.add(btn);
		}

		if (layerData.anims.length > 0) {
			activeAnim = layerData.anims[0].name;
			char.playAnim(activeAnim, true);
		} else {
			activeAnim = '';
		}
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
			var isHover = mx >= btn.x && mx <= btn.x + btn.width && my >= btn.y && my <= btn.y + btn.height;
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
			var isHover = mx >= btn.x && mx <= btn.x + btn.width && my >= btn.y && my <= btn.y + btn.height;
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

		var path = Paths.getPath('data/characters/$curCharacter', 'json');
		var json = haxe.Json.stringify(char.characterData, null, '\t');
		sys.io.File.saveContent(path, json);

		Console.log('[CharacterEditor] Saved: $path');
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

		movementMouse(hit);

		sectionTab.handleInput();

		handleUndoRedo();
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

		if (FlxG.mouse.wheel != 0)
			camEditor.zoom = Math.max(0.25, Math.min(3.0, camEditor.zoom + (FlxG.mouse.wheel > 0 ? 0.1 : -0.1)));

		if (Controls.BACK)
			MusicBeatState.switchState(() -> new DebugMenu());
	}
}

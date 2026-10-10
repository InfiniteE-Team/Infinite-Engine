package modding.editors;

import game.objects.Camera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import core.assets.FunkinSprite;
import game.objects.sprites.Character;
import flixel.addons.display.FlxGridOverlay;

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

		createCameras();

		final tile = FlxGridOverlay.createGrid(32, 32, FlxG.width * 5, FlxG.height * 5, true, 0xFF2C2C2C, 0xFF1F1F1F);
		final grid = new flixel.FlxSprite(-(FlxG.width * 5) * 0.32, -(FlxG.height * 5) * 0.3);
		grid.loadGraphic(tile);
		grid.scrollFactor.set(0, 0);
		add(grid);

		loadCharacter('idk', curCharacter, 0, 0);

		createHUD();

		FlxG.cameras.remove(camHud, false);
		FlxG.cameras.add(camHud, false);
	}

	function createHUD() {
		info = new FlxText(10, 40, FlxG.width, "char x: " + "\nchar y: ");
		info.setFormat(null, 16, 0xFFFFFFFF, 'left');
		info.scrollFactor.set(0, 0);
		info.cameras = [camHud];
		add(info);

		// animations
		createAnimList();

		hoverText = new FlxText(0, 0, 0, '');
		hoverText.setFormat(null, 14, FlxColor.YELLOW, 'left');
		hoverText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		hoverText.scrollFactor.set(0, 0);
		hoverText.cameras = [camHud];
		add(hoverText);
	}

	function createAnimList() {
		var animNames:Array<String> = [];
		for (layer in char.characterData.render.layers) {
			if (layer.anims == null)
				continue;
			for (anim in layer.anims) {
				if (!animNames.contains(anim.name))
					animNames.push(anim.name);
			}
		}

		if (animNames.length > 0) {
			activeAnim = animNames[0];
			char.playAnim(animNames[0], true);
		}

		for (i in 0...animNames.length) {
			var name = animNames[i];
			var btn = new FlxText(10, 100 + i * 22, 190, name);
			btn.setFormat(null, 14, 0xAAFFFFFF, 'left');
			btn.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
			btn.scrollFactor.set(0, 0);
			btn.cameras = [camHud];
			animButtons.push(btn);
			add(btn);
		}
	}

	function loadCharacter(id:String, name:String, x:Float, y:Float) {
		char = new Character(id, name, x, y);
		if (char == null) {
			Console.log("ERROR: Character GameOver not loaded");
			return;
		}
		for (layer in char.layers)
			add(layer);
		add(char);
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
				dragOffsetX = mousePos.x - char.x;
				dragOffsetY = mousePos.y - char.y;
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
			isDragging = false;
			isCamDragging = false;
		}

		if (isDragging) {
			var mousePos = FlxG.mouse.getWorldPosition(camEditor);
			char.x = mousePos.x - dragOffsetX;
			char.y = mousePos.y - dragOffsetY;
		}

		if (isCamDragging && FlxG.mouse.pressed) {
			camEditor.scroll.x -= (FlxG.mouse.deltaViewX / camEditor.zoom) * 0.5;
			camEditor.scroll.y -= (FlxG.mouse.deltaViewY / camEditor.zoom) * 0.5;

			camEditor.scroll.x = Math.max(-(FlxG.width * 2), Math.min(FlxG.width * 2, camEditor.scroll.x));
			camEditor.scroll.y = Math.max(-(FlxG.height * 2), Math.min(FlxG.height * 2, camEditor.scroll.y));
		}
	}

	function selectionAnims() {
		var mouseScreen = FlxG.mouse.getScreenPosition(camHud);
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

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (char != null)
			info.text = 'char x: ${flixel.math.FlxMath.roundDecimal(char.x, 2)}\nchar y: ${flixel.math.FlxMath.roundDecimal(char.y, 2)}';

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

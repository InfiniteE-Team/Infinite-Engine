package states.substates.menus.options;

import flixel.text.FlxText;
import game.objects.Camera;
import core.assets.FunkinSprite;

class ComboPositionSubstate extends states.substates.MusicBeatSubstate {
	var camSubstate:Camera;

	var previewRating:FunkinSprite;
	var previewNum:FunkinSprite;
	var hintText:FlxText;
	var posText:FlxText;

	var isDragging:Bool = false;
	var dragOffsetX:Float = 0;
	var dragOffsetY:Float = 0;

	var originalX:Float;
	var originalY:Float;

	public function new()
		super();

	override function create() {
		super.create();

		camSubstate = new Camera();
		camSubstate.bgColor = 0x00000000;
		FlxG.cameras.add(camSubstate, false);

		this.camera = camSubstate;

		originalX = SaveData.data.comboPosX;
		originalY = SaveData.data.comboPosY;

		if (FlxG.mouse != null)
			FlxG.mouse.visible = true;

		final bg = new flixel.FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xBB000000);
		bg.scrollFactor.set(0, 0);
		bg.alpha = 0.95;
		add(bg);

		previewRating = new FunkinSprite(0, 0, true);
		previewRating.loadGraphic(Paths.getPath('game/hud/normal/score/sick', 'image'));
		previewRating.setGraphicSize(Std.int(previewRating.width * 0.7));
		previewRating.updateHitbox();
		previewRating.scrollFactor.set(0, 0);
		add(previewRating);

		previewNum = new FunkinSprite(0, 0, true);
		previewNum.loadGraphic(Paths.getPath('game/hud/normal/score/nums/digit-0', 'image'));
		previewNum.setGraphicSize(Std.int(previewNum.width * 0.38));
		previewNum.updateHitbox();
		previewNum.scrollFactor.set(0, 0);
		add(previewNum);

		posText = new FlxText(10, FlxG.height - 40, 0, '');
		posText.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFFFFFFFF, 'left');
		posText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1.5, 1);
		posText.scrollFactor.set(0, 0);
		add(posText);

		hintText = new FlxText(0, FlxG.height - 40, FlxG.width, 'Click and drag to move  -  ENTER to save  -  BACK to cancel');
		hintText.setFormat(Paths.getPath('Funkin.otf', 'font'), 18, 0xFFFFFFFF, 'center');
		hintText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1.5, 1);
		hintText.scrollFactor.set(0, 0);
		add(hintText);

		updatePreviewPosition();
	}

	function updatePreviewPosition() {
		var cx:Float = SaveData.data.comboPosX;
		var cy:Float = SaveData.data.comboPosY;

		previewRating.x = cx - 160;
		previewRating.y = cy - 90;

		previewNum.x = cx - 90;
		previewNum.y = cy + 20;

		posText.text = 'X: ${Std.int(cx)}  Y: ${Std.int(cy)}';
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;

		if (FlxG.mouse.justPressed) {
			if (previewRating.overlapsPoint(FlxG.mouse.getWorldPosition(camSubstate), true, camSubstate)
				|| previewNum.overlapsPoint(FlxG.mouse.getWorldPosition(camSubstate), true, camSubstate)) {
				isDragging = true;
				dragOffsetX = mx - SaveData.data.comboPosX;
				dragOffsetY = my - SaveData.data.comboPosY;
			}
		}

		if (FlxG.mouse.released)
			isDragging = false;

		if (isDragging) {
			SaveData.data.comboPosX = mx - dragOffsetX;
			SaveData.data.comboPosY = my - dragOffsetY;

			SaveData.data.comboPosX = Math.max(160, Math.min(FlxG.width - 50, SaveData.data.comboPosX));
			SaveData.data.comboPosY = Math.max(90, Math.min(FlxG.height - 50, SaveData.data.comboPosY));

			updatePreviewPosition();
		}

		if (Controls.ACCEPT) {
			SaveData.flush();
			close();
		}

		if (Controls.BACK) {
			SaveData.data.comboPosX = originalX;
			SaveData.data.comboPosY = originalY;
			close();
		}
	}

	override function destroy() {
		super.destroy();

		if (camSubstate != null)
			FlxG.cameras.remove(camSubstate, true);
		camSubstate = null;
	}
}

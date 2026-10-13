package modding.editors.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class StatsButton extends Button {
	var dragHandle:FlxSprite;
	var deleteButton:FlxText;
	var onDragCallback:(newIndex:Int) -> Void;
	var onDeleteCallback:Void->Void;

	public var dragging:Bool = false;

	var dragStartY:Float = 0;
	var myIndex:Int = 0;
	var totalItems:Int = 1;
	var itemHeight:Float = 40;

	var baseY:Float = 0;
	var dragVisualY:Float = 0;

	override public function new(x:Float, y:Float, text:String, ?onClick:Void->Void, ?cam:game.objects.Camera, ?onDrag:(Int->Void), ?onDelete:Void->Void) {
		super(x, y, text, onClick, cam);

		remove(bg, true);
		bg.destroy();
		remove(label, true);
		label.destroy();

		bg = new FlxSprite();
		bg.frames = Paths.getPath('menus/editors/ui/cells', 'animated');
		bg.animation.addByPrefix('idle', 'Cel0', 24, false);
		bg.animation.play('idle');
		bg.scale.set(0.6, 0.6);
		bg.updateHitbox();
		add(bg);

		var labelOffsetX = 6;
		label = new FlxText(labelOffsetX, 0, bg.width - labelOffsetX - 60, text);
		label.setFormat(Paths.getPath('Funkin.otf', 'font'), 24, flixel.util.FlxColor.WHITE, 'left');
		label.y = (bg.height / 2) - (label.height / 2);
		add(label);

		if (onDrag != null) {
			onDragCallback = onDrag;
			onDeleteCallback = onDelete;

			dragHandle = new FlxSprite();
			dragHandle.loadGraphic(Paths.getPath('menus/editors/ui/barsContent', 'image'));
			dragHandle.scale.set(0.6, 0.6);
			dragHandle.updateHitbox();
			dragHandle.x = bg.width - dragHandle.width - 6;
			dragHandle.y = (bg.height / 2) - (dragHandle.height / 2);
			add(dragHandle);

			deleteButton = new FlxText(0, 0, 0, 'X');
			deleteButton.setFormat(Paths.getPath('Funkin.otf', 'font'), 28, 0xFFFFFFFF, 'center');
			deleteButton.x = dragHandle.x - deleteButton.width - 30;
			deleteButton.y = (bg.height / 2) - (deleteButton.height / 2);
			add(deleteButton);
		}
	}

	public function setDragContext(index:Int, total:Int, stepHeight:Float) {
		myIndex = index;
		totalItems = total;
		itemHeight = stepHeight;
		baseY = y;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var mouse = FlxG.mouse.getViewPosition(cam != null ? cam : FlxG.camera);
		var mx = mouse.x;
		var my = mouse.y;

		if (onDragCallback == null || dragHandle == null)
			return;

		var deleteHit = mx >= deleteButton.x
			&& mx <= deleteButton.x + deleteButton.width
			&& my >= deleteButton.y
			&& my <= deleteButton.y + deleteButton.height;

		deleteButton.color = deleteHit ? 0xFFFFD4D4 : 0xFFFFFFFF;

		if (deleteHit && FlxG.mouse.justPressed)
			onDeleteCallback();

		var handleHit = mx >= dragHandle.x
			&& mx <= dragHandle.x + dragHandle.width
			&& my >= dragHandle.y
			&& my <= dragHandle.y + dragHandle.height;

		if (handleHit && FlxG.mouse.justPressed) {
			dragging = true;
			dragStartY = my;
			dragVisualY = y;
			FlxTween.cancelTweensOf(this);
			FlxTween.tween(this, {y: baseY - 4}, 0.08, {ease: FlxEase.quadOut});
			alpha = 0.75;
		}

		if (dragging) {
			dragHandle.color = 0xFFFFCC00;
			this.y = dragVisualY + (my - dragStartY);

			if (FlxG.mouse.justReleased) {
				dragging = false;
				dragHandle.color = 0xFFFFFFFF;
				alpha = 1.0;

				FlxTween.cancelTweensOf(this);
				FlxTween.tween(this, {y: baseY}, 0.1, {ease: FlxEase.quadOut});

				var delta = my - dragStartY;
				var steps = Math.round(delta / itemHeight);
				if (steps != 0) {
					var newIndex = Std.int(Math.max(0, Math.min(totalItems - 1, myIndex + steps)));
					if (newIndex != myIndex)
						onDragCallback(newIndex);
				}
			}
		} else {
			dragHandle.color = handleHit ? 0xFFFFCC00 : 0xFFFFFFFF;
		}
	}
}

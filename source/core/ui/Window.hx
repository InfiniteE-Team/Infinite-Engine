package core.ui;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.system.System;
import lime.app.Application;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class Window extends Sprite {
	var isDragging:Bool = false;
	var offsetX:Float = 0;
	var offsetY:Float = 0;

	var currentTween:FlxTween;

	public function new() {
		super();
		addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(e:Event) {
		removeEventListener(Event.ADDED_TO_STAGE, init);

		this.alpha = 0;
		this.visible = false;

		var topBar = new Sprite();
		topBar.graphics.beginFill(0x222222);
		topBar.graphics.drawRect(0, 0, 1280, 40);
		topBar.alpha = 0.9;
		topBar.graphics.endFill();
		addChild(topBar);

		var title = new TextField();
		title.text = "Infinite Engine";
		title.autoSize = openfl.text.TextFieldAutoSize.LEFT;
		title.defaultTextFormat = new openfl.text.TextFormat(Paths.getPath("Funkin.otf", "font"), 20, 0xEBFCFF);
		title.x = 25;
		title.y = 10;
		title.selectable = false;
		addChild(title);

		var minBtn = new Sprite();

		var minBg = new Sprite();
		minBg.graphics.beginFill(0x555555);
		minBg.graphics.drawRect(0, 0, 45, 40);
		minBg.graphics.endFill();
		minBg.alpha = 0;
		minBtn.addChild(minBg);

		var iconMin = new Sprite();
		iconMin.graphics.lineStyle(2, 0xFFFFFF);
		iconMin.graphics.moveTo(18, 24);
		iconMin.graphics.lineTo(27, 24);
		minBtn.addChild(iconMin);

		minBtn.x = 1280 - 90;
		minBtn.y = 0;
		minBtn.buttonMode = true;

		minBtn.graphics.beginFill(0x000000, 0);
		minBtn.graphics.drawRect(0, 0, 45, 40);
		minBtn.graphics.endFill();

		addChild(minBtn);

		minBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent) {
			minBg.alpha = 1;
		});

		minBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent) {
			minBg.alpha = 0;
		});

		minBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
			Application.current.window.minimized = true;
		});

		var closeBtn = new Sprite();

		var closeBg = new Sprite();
		closeBg.graphics.beginFill(0xE81123);
		closeBg.graphics.drawRect(0, 0, 45, 40);
		closeBg.graphics.endFill();
		closeBg.alpha = 0;
		closeBtn.addChild(closeBg);

		var iconX = new Sprite();
		iconX.graphics.lineStyle(2, 0xFFFFFF);
		iconX.graphics.moveTo(18, 15);
		iconX.graphics.lineTo(27, 24);
		iconX.graphics.moveTo(27, 15);
		iconX.graphics.lineTo(18, 24);
		closeBtn.addChild(iconX);

		closeBtn.x = 1280 - 45;
		closeBtn.y = 0;
		closeBtn.buttonMode = true;

		closeBtn.graphics.beginFill(0x000000, 0);
		closeBtn.graphics.drawRect(0, 0, 45, 40);
		closeBtn.graphics.endFill();

		addChild(closeBtn);

		closeBtn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent) {
			closeBg.alpha = 1;
		});

		closeBtn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent) {
			closeBg.alpha = 0;
		});

		closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
			System.exit(0);
		});

		topBar.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
			isDragging = true;
			offsetX = e.stageX;
			offsetY = e.stageY;
		});

		stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) {
			isDragging = false;
		});

		stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
			if (e.stageY <= 50 || isDragging) {
				if (!this.visible) {
					this.visible = true;
					if (currentTween != null)
						currentTween.cancel();
					currentTween = FlxTween.tween(this, {alpha: 1}, 0.15, {ease: FlxEase.quartOut});
				}
			} else {
				if (this.visible && this.alpha > 0 && !isDragging) {
					if (currentTween != null)
						currentTween.cancel();
					currentTween = FlxTween.tween(this, {alpha: 0}, 0.15, {
						ease: FlxEase.quartOut,
						onComplete: function(t:FlxTween) {
							if (this.alpha == 0)
								this.visible = false;
						}
					});
				}
			}

			if (isDragging) {
				var win = Application.current.window;
				win.x = Std.int(win.x + (e.stageX - offsetX));
				win.y = Std.int(win.y + (e.stageY - offsetY));
			}
		});
	}
}

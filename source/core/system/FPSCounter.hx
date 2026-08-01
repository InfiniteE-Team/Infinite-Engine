package core.system;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.events.Event;

class FPSCounter extends Sprite {
	public static var instance:FPSCounter = null;

	var bg = new Shape();
	var fps:core.system.FPS;

	public function new(x:Float, y:Float, color:Int) {
		super();
		instance = this;

		this.x = x;
		this.y = y;

		fps = new core.system.FPS(5, 5, color);

		addChild(bg);
		addChild(fps);

		updateVisibility();

		addEventListener(Event.ENTER_FRAME, _enter);
		addEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
	}

	private function _enter(e:Event) {
		if (!visible)
			return;
		drawBackground();
	}

	var lastW:Float = 0;
	var lastH:Float = 0;

	public function drawBackground() {
		// bg black
		var w = fps.textWidth + 8 * 2;
		var h = fps.textHeight + 8 * 2;

		if (w != lastW || h != lastH) {
			bg.graphics.clear();
			lastW = w;
			lastH = h;
			bg.graphics.beginFill(0x111111, 0.85);
			bg.graphics.drawRoundRect(-3, -3, w, h, 6, 6);
			bg.graphics.endFill();
		}
	}

	public function updateVisibility():Void {
		if (Reflect.field(SaveData, "data") != null && SaveData.data != null) {
			this.visible = SaveData.data.fpsVisible;
		} else {
			this.visible = true;
		}
	}

	private function _onRemoved(e:Event):Void {
		removeEventListener(Event.ENTER_FRAME, _enter);
		removeEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
	}
}

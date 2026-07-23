package core.system;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.events.Event;

class FPSCounter extends Sprite {
	var bg = new Shape();
    var fps = new core.system.FPS(2,2,0xFFFFFF);

	public function new(x:Float, y:Float, color:Int) {
		super();

		this.x = x;
		this.y = y;

		addChild(bg);
		addChild(fps);

		addEventListener(Event.ENTER_FRAME, _enter);
	}

	public function _enter(e:Event)
	{
		drawBackground();
	}

	var lastW:Float = 0;
	var lastH:Float = 0;

	public function drawBackground() {
        // bg black
		var w = fps.textWidth + 8 * 2;
        var h = fps.textHeight + 8 * 2;

		if (w != lastW || h != lastH){
			bg.graphics.clear();
			lastW = w;
			lastH = h;
			bg.graphics.beginFill(0x111111, 0.85);
			bg.graphics.drawRoundRect(-6, -6, w, h, 6, 6);
			bg.graphics.endFill();
		}
	}
}

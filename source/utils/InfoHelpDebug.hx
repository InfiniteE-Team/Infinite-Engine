package utils;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;

class InfoHelpDebug extends FlxText {
	var open:Bool = false;

	public function new(x:Float, y:Float, ?fieldWith:Float = 0) {
		super(x, y, fieldWith);
		this.x = x;
		this.y = y;
		createUIInfo();
	}

	public function createUIInfo() {
		text = "Beats: - Steps: ";
        size = 18;
		autoSize = true;
		y -= 25;

		if (FlxG.cameras.list.length > 1) {
            this.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        }
	}

	public function openUI() {
		if (!open) {
			FlxTween.tween(this, {y: y + 25}, 0.2);
			open = true;
		} else {
			FlxTween.tween(this, {y: y - 25}, 0.2);
			open = false;
		}
	}
}

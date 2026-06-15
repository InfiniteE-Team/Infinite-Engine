package;

import core.system.FPSCounter;
import openfl.display.Sprite;

class Main extends Sprite {
	public var fps:FPSCounter = new FPSCounter(5, 5, 0xFFFFFF);

	public function new() {
		super();
		mainGame();

		stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	function mainGame() {
		addChild(new core.Game(core.ConfigMain));
		addChild(fps);
	}

	private function onKeyDown(e:openfl.events.KeyboardEvent):Void {
		if (e.keyCode == flash.ui.Keyboard.F11) {
			FlxG.fullscreen = !FlxG.fullscreen;
		}
	}
}

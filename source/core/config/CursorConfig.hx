package core.config;

import core.json.extensions.SpriteData.ObjectData;
import core.json.extensions.SpriteData.AnimData;
import core.assets.FunkinSprite;

class CursorConfig extends FunkinSprite {
	// yep
	var cursorProps:ObjectData;

	var cursorAnims:AnimData;

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y);
	}

	public function loadCursor() {
		cursorProps = FormatJson.readJson(Paths.getPath('data/cursorConfig', "json"));
		loadProps(cursorProps, 'cursor');

		if (this.graphic == null || this.graphic.bitmap == null) {
			Trace.traceOnce("CursorConfig: graphic is null, cursor not loaded",true);
			return;
		}

		FlxG.mouse.load(this.graphic.bitmap);
		FlxG.mouse.visible = true;
	}
}

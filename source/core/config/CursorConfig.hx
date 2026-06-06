package core.config;
import utils.UtilsData;
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
		cursorProps = UtilsData.readJson(Paths.getPath('data/cursorConfig', "json"));

		loadProps(cursorProps, 'cursor');

		FlxG.mouse.load(this.graphic, Std.int(this.scale.x), Std.int(this.scale.y));
		FlxG.mouse.visible = true;
	}
}

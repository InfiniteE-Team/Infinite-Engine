package core.config;

import core.json.extensions.SpriteData.ObjectData;
import core.json.extensions.SpriteData.AnimData;
import core.assets.FunkinSprite;

class CursorConfig extends FunkinSprite {
	var cursorProps:ObjectData;

	var cursorAnims:AnimData;

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y);
	}

	public function loadCursor() {
		cursorProps = FormatJson.readJson(Paths.getPath('data/cursorConfig', "json"));
		loadProps(cursorProps, 'cursor');

		if (this.graphic == null || this.graphic.bitmap == null) {
			Console.log("CursorConfig: graphic is null, cursor not loaded", true);
			return;
		}

		var file = core.assets.Library.findLib('images/cursor/${cursorProps.path}.png');
		if (file != null && sys.FileSystem.exists(file))
			cursorBitmap = openfl.display.BitmapData.fromFile(file);

		if (cursorBitmap == null)
			cursorBitmap = this.graphic.bitmap;

		FlxG.mouse.load(cursorBitmap);
		FlxG.mouse.visible = true;

		if (!clickHooked) {
			clickHooked = true;
			FlxG.signals.postUpdate.add(checkClick);
		}
	}

	static var cursorBitmap:openfl.display.BitmapData;
	static var clickHooked:Bool = false;
	static var bounceTween:flixel.tweens.FlxTween;

	static function checkClick():Void {
		if (FlxG.mouse.justPressed)
			bounce();
	}

	public static function bounce():Void {
		var container = FlxG.mouse.cursorContainer;
		if (container == null)
			return;

		if (bounceTween != null)
			bounceTween.cancel();

		bounceTween = flixel.tweens.FlxTween.num(0.65, 1, 0.4, {ease: flixel.tweens.FlxEase.backOut}, v -> {
			container.scaleX = container.scaleY = v;
		});
	}

	public static function refresh():Void {
		if (ConfigMain.cursor == null)
			return;
		if (cursorBitmap != null)
			FlxG.mouse.load(cursorBitmap);
	}
}
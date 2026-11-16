package modding.editors.ui;

class Utils {
	public static function roundGraphic(width:Float, height:Float, ?color:flixel.util.FlxColor = 0xC80338):flixel.graphics.FlxGraphic {
		final w:Int = Math.ceil(width);
		final h:Int = Math.ceil(height);

		final shape:openfl.display.Shape = new openfl.display.Shape();

        shape.graphics.beginFill(color, 1.0);
		shape.graphics.drawRoundRect(0, 0, w, h, 12 * 2, 12 * 2);
		shape.graphics.endFill();

		final bitmap:openfl.display.BitmapData = new openfl.display.BitmapData(w, h, true, 0x00000000);
		bitmap.draw(shape);

		return flixel.graphics.FlxGraphic.fromBitmapData(bitmap);
	}
}

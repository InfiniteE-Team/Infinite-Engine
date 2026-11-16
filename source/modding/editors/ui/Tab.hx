package modding.editors.ui;

class Tab extends flixel.group.FlxSpriteContainer {
	public var bg:flixel.FlxSprite;

	public function new(?x:Float = 0, ?y:Float = 0, ?width:Float = 1, ?height:Float = 1) {
		super(x, y);

		final w:Int = Math.ceil(width);
		final h:Int = Math.ceil(height);

		final colors:Array<Int> = [0x29042E, 0x29042E, 0x00032B];
		final alphas:Array<Float> = [1.0, 1.0, 1.0];
		final ratios:Array<Int> = [0, 80, 255];

		final matrix:openfl.geom.Matrix = new openfl.geom.Matrix();
		matrix.createGradientBox(w, h, Math.PI / 2, 0, 0);

		final shape:openfl.display.Shape = new openfl.display.Shape();
		shape.graphics.beginGradientFill(openfl.display.GradientType.LINEAR, colors, alphas, ratios, matrix);

		shape.graphics.drawRoundRect(0, 0, w, h, 24 * 2, 24 * 2);
		shape.graphics.endFill();

		final bitmap:openfl.display.BitmapData = new openfl.display.BitmapData(w, h, true, 0x00000000);
		bitmap.draw(shape);

		bg = new flixel.FlxSprite(0, 0);
		bg.loadGraphic(flixel.graphics.FlxGraphic.fromBitmapData(bitmap, false, null, false));
		add(bg);
	}

	public function addItem(item:flixel.FlxSprite, offsetX:Float = 0, offsetY:Float = 0):Void {
		item.setPosition(this.x + offsetX, this.y + offsetY);
		add(item);
	}

	public function getWidth():Float
		return bg.width;

	public function getHeight():Float
		return bg.height;
}

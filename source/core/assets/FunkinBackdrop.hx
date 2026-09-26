package core.assets;

class FunkinBackdrop extends FunkinSprite {
	public var velocityX:Float = 0;
	public var velocityY:Float = 0;

	public var repeatX:Bool = true;
	public var repeatY:Bool = true;

	public var spacingX:Float = 0;
	public var spacingY:Float = 0;

	var _offsetX:Float = 0;
	var _offsetY:Float = 0;

	public function new(x:Float = 0, y:Float = 0, velocityX:Float = 0, velocityY:Float = 0, repeatX:Bool = true, repeatY:Bool = true) {
		super(x, y);
		this.velocityX = velocityX;
		this.velocityY = velocityY;
		this.repeatX = repeatX;
		this.repeatY = repeatY;
		moves = false;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (velocityX != 0) {
			_offsetX += velocityX * elapsed;
			_offsetX %= (frameWidth + spacingX);
		}
		if (velocityY != 0) {
			_offsetY += velocityY * elapsed;
			_offsetY %= (frameHeight + spacingY);
		}
	}

	override public function draw():Void {
		if (graphic == null || frameWidth == 0 || frameHeight == 0)
			return;

		var tileW = frameWidth + spacingX;
		var tileH = frameHeight + spacingY;

		var cam = cameras[0] ?? FlxG.camera;

		var camLeft = cam.scroll.x;
		var camTop = cam.scroll.y;

		var cols = repeatX ? Math.ceil(cam.width / cam.zoom / tileW) + 2 : 1;
		var rows = repeatY ? Math.ceil(cam.height / cam.zoom / tileH) + 2 : 1;

		var startCol = repeatX ? Math.floor((camLeft + x - _offsetX) / tileW) : 0;
		var startRow = repeatY ? Math.floor((camTop + y - _offsetY) / tileH) : 0;

		var ox = x;
		var oy = y;

		for (row in 0...rows) {
			for (col in 0...cols) {
				x = (startCol + col) * tileW + _offsetX - (repeatX ? camLeft : 0) + (repeatX ? 0 : ox);
				y = (startRow + row) * tileH + _offsetY - (repeatY ? camTop : 0) + (repeatY ? 0 : oy);
				super.draw();
			}
		}

		x = ox;
		y = oy;
	}
}

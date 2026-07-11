package game.objects;

class Camera extends flixel.FlxCamera {
	public function new(?x:Float = 0.0, ?y:Float = 0.0, ?width:Int = 0, ?height:Int = 0, ?zoom:Float = 0.0) {
		super(x, y, width, height, zoom);
		pruneEmptyFilters();
	}

	public function pruneEmptyFilters():Void {
        if (filters == null)
            return;
        
        filters = filters.filter(f -> f != null);
        
        if (filters.length == 0)
            filters = null;
    }

	override function set_angle(val:Float):Float {
		return angle = val;
	}

	override public function drawPixels(?frame:flixel.graphics.frames.FlxFrame, ?pixels:openfl.display.BitmapData, matrix:flixel.math.FlxMatrix, ?transform:openfl.geom.ColorTransform, ?blend:openfl.display.BlendMode,
			?smoothing:Bool = false, ?shader:flixel.system.FlxAssets.FlxShader):Void {
		if (!FlxG.renderBlit && angle != 0) {
			matrix.translate(-width / 2, -height / 2);

			var rad:Float = angle * Math.PI / 180;
			matrix.rotateWithTrig(Math.cos(rad), Math.sin(rad));

			matrix.translate(width / 2, height / 2);
		}

		super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
	}
}
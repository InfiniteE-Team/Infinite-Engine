package game.objects;
import flixel.FlxCamera;

class Camera extends FlxCamera {
	public function new(?x:Float = 0.0, ?y:Float = 0.0, ?width:Int = 0, ?height:Int = 0, ?zoom:Float = 0.0) {
		super(x, y, width, height, zoom);
        pruneEmptyFilters();
	}

	public static function pruneEmptyFilters(?cam:FlxCamera):Void {
		if (cam == null)
			cam = FlxG.camera;
		if (cam.filters == null)
			return;
		cam.filters = cam.filters.filter(f -> f != null);
		if (cam.filters.length == 0)
			cam.filters = null;
	}
}

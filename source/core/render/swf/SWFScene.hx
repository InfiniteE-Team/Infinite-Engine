package core.render.swf;

import foxlite.FoxCamera;
import foxlite.FoxScene;
import flixel.FlxCamera;

class SWFScene {
	public static var instance:FoxScene;
	public static var foxCam:FoxCamera;
	public static final PIXEL_SIZE:Float = 0.01;

	public static function init():Void {
		if (instance != null)
			return;

		instance = new FoxScene(FlxG.width, FlxG.height);

		foxCam = new FoxCamera(0, 0, 5, 0x00000000, true);
		foxCam.fov = FlxG.width * PIXEL_SIZE;
		foxCam.near = 0.1;
		foxCam.far = 100.0;

		instance.foxCameras.push(foxCam);
	}

	public static function syncCamera(?flxCam:FlxCamera):Void {
		if (instance == null || foxCam == null)
			return;
		var cam = flxCam ?? FlxG.camera;

		foxCam.fov = FlxG.width * PIXEL_SIZE / cam.zoom;
	}

	public static inline function worldToFox(wx:Float, wy:Float, ?flxCam:FlxCamera):{x:Float, y:Float} {
		var cam = flxCam ?? FlxG.camera;
		var ps = PIXEL_SIZE;
		var hw = FlxG.width * 0.5;
		var hh = FlxG.height * 0.5;

		return {
			x: ((wx - cam.scroll.x) * cam.zoom - hw) * ps,
			y: -(((wy - cam.scroll.y) * cam.zoom - hh) * ps)
		};
	}

	public static function destroy():Void {
		instance?.destroy();
		instance = null;
		foxCam = null;
	}
}

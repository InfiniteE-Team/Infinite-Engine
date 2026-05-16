package game.controllers;
import game.objects.Camera;

class CameraController {
	// yep
	public var camGame:Camera;
	public var camHUD:Camera;
	public var defaultZoom:Float = 1.0;

	public var zoomEnabled:Bool = true;

	// === CAMERA ===
	public static inline var CAM_LERP_SPEED:Float = 2.4;
	public static inline var CAM_ZOOM_AMOUNT:Float = 0.015;
	public static inline var CAM_HUD_ZOOM_AMOUNT:Float = 0.03;
	public static inline var CAM_NOTE_OFFSET:Float = 30.0;

	public function new(camGame:Camera, camHUD:Camera) {
		this.camGame = camGame;
		this.camHUD = camHUD;
		resolveZoom();
	}

	public function resolveZoom() {
		camGame.zoom = defaultZoom;
	}

	public function update(elapsed:Float):Void {
		lerpZoom(elapsed);
	}

	public function lerpZoom(elapsed:Float):Void {
		var lerpVal:Float = flixel.math.FlxMath.bound(elapsed * 3.125, 0, 1);
		camGame.zoom = flixel.math.FlxMath.lerp(camGame.zoom, defaultZoom, lerpVal);
		camHUD.zoom  = flixel.math.FlxMath.lerp(camHUD.zoom, 1.0, lerpVal);
	}

	public function bumpZoom() {
		if (!zoomEnabled)
			return;
		var bumpLimit:Float = 1.35;
		if (camGame.zoom < bumpLimit) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}
	}

	public function destroy()
	{

	}
}

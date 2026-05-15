package game.controllers;
import game.objects.Camera;

class CameraController {
	// yep
	public var camGame:Camera;
	public var camHUD:Camera;
	public var defaultZoom:Float = 1.0;

	public var zoomEnabled:Bool = true;

	public function new(camGame:Camera, camHUD:Camera) {
		this.camGame = camGame;
		this.camHUD = camHUD;
		camGame.zoom = defaultZoom;
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

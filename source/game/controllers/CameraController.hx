package game.controllers;

import flixel.FlxObject;
import game.objects.Camera;
import flixel.math.FlxMath;
import game.objects.sprites.Character;

class CameraController {
	// yep
	public var camGame:Camera;
	public var camHUD:Camera;
	public var defaultZoom:Float = 1.0;

	public var camPoint:FlxObject;

	public var char:Character = null;

	public var zoomEnabled:Bool = true;

	public var existsCamEvents:Bool = false;

	public var lerp:Float = 0.04;

	public function new(camGame:Camera, camHUD:Camera) {
		this.camGame = camGame;
		this.camHUD = camHUD;

		camPoint = new FlxObject(0, 0, 1, 1);
		camGame.follow(camPoint, LOCKON, lerp);

		camGame.zoom = defaultZoom;
	}

	public function update(elapsed:Float):Void {
		followChar(char);

		lerpZoom(elapsed);
	}

	public function followChar(char:Character) {
		if (char != null) {
			var pos = char.getCamPosition();
			moveCameraTo(pos.x, pos.y);
		}
	}

	public function lerpZoom(elapsed:Float):Void {
		var lerpVal:Float = FlxMath.bound(elapsed * 3.125, 0, 1);
		camGame.zoom = FlxMath.lerp(camGame.zoom, defaultZoom, lerpVal);
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1.0, lerpVal);
	}

	public function bumpZoom() {
		if (!zoomEnabled)
			return;
		if (camGame.zoom < 1.35) {
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}
	}

	public function moveCameraTo(x:Float, y:Float) {
		camPoint.setPosition(x, y);
	}

	public function destroy() {
		if (camPoint != null)
			camPoint.destroy();
		camPoint = null;
	}
}

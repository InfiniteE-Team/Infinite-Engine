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

	public var isLock:Bool = false;

	public var char:Character = null;

	public var zoomEnabled:Bool = true;

	public var existsCamEvents:Bool = false;

	public var lerp:Float = 0.04;

	public var stageZoom:Float = 1.0;
	public var bopEvery:Int = 4;
	public var bopIntensity:Float = 1.0;

	var zoomTween:flixel.tweens.FlxTween;

	public var focusX:Float = 0;
	public var focusY:Float = 0;

	var focusTween:flixel.tweens.FlxTween;
	var focusProgress:Float = 0;
	var focusStartX:Float = 0;
	var focusStartY:Float = 0;
	var fixedX:Float = 0;
	var fixedY:Float = 0;

	public function new(camGame:Camera, camHUD:Camera) {
		this.camGame = camGame;
		this.camHUD = camHUD;

		camPoint = new FlxObject(0, 0, 1, 1);
		camGame.follow(camPoint, LOCKON, lerp);

		camGame.zoom = defaultZoom;
	}

	public function update(elapsed:Float):Void {
		if (focusTween != null) {
			var tx = fixedX, ty = fixedY;
			if (char != null) {
				var pos = char.getCamPosition();
				tx = pos.x + focusX;
				ty = pos.y + focusY;
			}
			moveCameraTo(FlxMath.lerp(focusStartX, tx, focusProgress), FlxMath.lerp(focusStartY, ty, focusProgress));
		} else if (!isLock && char != null) {
			var pos = char.getCamPosition();
			moveCameraTo(pos.x + focusX, pos.y + focusY);
		}

		lerpZoom(elapsed);
	}

	public function followChar(char:Character) {
		if (!isLock) {
			if (char != null) {
				var pos = char.getCamPosition();
				moveCameraTo(pos.x, pos.y);
			}
		}
	}

	public function snapCameraTo(x:Float, y:Float):Void {
		camPoint.setPosition(x, y);
		camGame.scroll.set(x - (camGame.width * 0.5), y - (camGame.height * 0.5));
	}

	public function centerCamera(?a:Character, ?b:Character, ?lock:Bool = true) {
		cancelFocusTween();
		final aCam = a.getCamPosition();
		final bCam = b.getCamPosition();

		moveCameraTo((aCam.x + bCam.x) / 2, (aCam.y + bCam.y) / 2);

		isLock = lock;
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
			camGame.zoom += 0.015 * bopIntensity;
			camHUD.zoom += 0.03 * bopIntensity;
		}
	}

	public function zoomTo(target:Float, duration:Float, ?ease:flixel.tweens.FlxEase.EaseFunction):Void {
		zoomTween?.cancel();
		if (duration <= 0 || ease == null) {
			defaultZoom = target;
			camGame.zoom = target;
			return;
		}
		zoomTween = flixel.tweens.FlxTween.num(defaultZoom, target, duration, {ease: ease}, v -> defaultZoom = v);
	}

	public function focusOn(target:Null<Character>, x:Float, y:Float, duration:Float, ?ease:flixel.tweens.FlxEase.EaseFunction, snap:Bool = false):Void {
		cancelFocusTween();
		isLock = false;
		char = target;
		focusX = target != null ? x : 0;
		focusY = target != null ? y : 0;

		var dest = target != null ? target.getCamPosition() : null;
		var destX = dest != null ? dest.x + x : x;
		var destY = dest != null ? dest.y + y : y;
		fixedX = x;
		fixedY = y;

		if (snap || (ease != null && duration <= 0)) {
			snapCameraTo(destX, destY);
			return;
		}
		if (ease == null) {
			moveCameraTo(destX, destY);
			return;
		}

		focusStartX = camGame.scroll.x + camGame.width * 0.5;
		focusStartY = camGame.scroll.y + camGame.height * 0.5;
		focusProgress = 0;
		camGame.followLerp = 1;
		focusTween = flixel.tweens.FlxTween.num(0, 1, duration, {
			ease: ease,
			onComplete: _ -> cancelFocusTween()
		}, v -> focusProgress = v);
	}

	function cancelFocusTween():Void {
		if (focusTween == null)
			return;
		focusTween.cancel();
		focusTween = null;
		camGame.followLerp = lerp;
	}

	public function moveCameraTo(x:Float, y:Float) {
		camPoint.setPosition(x, y);
	}

	public function destroy() {
		zoomTween?.cancel();
		focusTween?.cancel();
		if (camPoint != null)
			camPoint.destroy();
		camPoint = null;
	}
}

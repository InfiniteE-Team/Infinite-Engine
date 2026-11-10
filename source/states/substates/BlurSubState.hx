package states.substates;

import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import core.render.shaders.hardcode.BlurShader;

class BlurSubState extends MusicBeatSubstate {
	public var camSubStateBlur:FlxCamera;

	var blurShader:BlurShader;
	var blurFilter:ShaderFilter;

	var blurAmount:Float;

	var targetCameras:Array<FlxCamera>;

	var _blurAll:Bool;

	var _prevFilters:Map<FlxCamera, Array<BitmapFilter>>;

	var blurInTween:FlxTween;

	public function new(blurAmount:Float = 2.0, ?targetCams:Array<FlxCamera>, animateIn:Bool = true) {
		super();
		this.blurAmount = blurAmount;
		this.targetCameras = targetCams;
		this._blurAll = (targetCams == null);
		this._animateIn = animateIn;
	}

	var _animateIn:Bool;

	override function create():Void {
		var initialBlur = _animateIn ? 0.0 : blurAmount;
		blurShader = new BlurShader(initialBlur);
		blurFilter = new ShaderFilter(blurShader);
		_prevFilters = new Map();

		if (_blurAll)
			targetCameras = FlxG.cameras.list.copy();

		_applyBlurToCameras(targetCameras);

		camSubStateBlur = new FlxCamera();
		camSubStateBlur.bgColor = 0x00000000;
		FlxG.cameras.add(camSubStateBlur, false);
		cameras = [camSubStateBlur];

		if (_animateIn) {
			blurInTween = FlxTween.num(0.0, blurAmount, 0.25, {ease: FlxEase.quadOut}, function(v:Float) {
				blurShader.setBlur(v);
			});
		}

		super.create();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (_blurAll) {
			for (cam in FlxG.cameras.list) {
				if (cam == camSubStateBlur || _prevFilters.exists(cam))
					continue;
				_applyBlurToCameras([cam]);
				targetCameras.push(cam);
			}
		}
	}

	override function destroy():Void {
		if (blurInTween != null) {
			blurInTween.cancel();
			blurInTween = null;
		}

		if (_prevFilters != null) {
			for (cam => prev in _prevFilters)
				if (cam != null)
					cam.filters = prev;
			_prevFilters.clear();
		}

		FlxG.cameras.remove(camSubStateBlur, true);
		camSubStateBlur = null;

		super.destroy();
	}

	function _applyBlurToCameras(cams:Array<FlxCamera>):Void {
		for (cam in cams) {
			var prev = (cam.filters != null) ? cam.filters.copy() : [];
			_prevFilters.set(cam, prev);
			cam.filters = prev.concat([blurFilter]);
		}
	}

	public function setBlur(amount:Float):Void {
		blurAmount = amount;
		blurShader.setBlur(amount);
	}

	public function animateOutAndClose(duration:Float = 0.2):Void {
		FlxTween.num(blurAmount, 0.0, duration, {ease: FlxEase.quadIn}, function(v:Float) {
			blurShader.setBlur(v);
		}).onComplete = function(_) close();
	}
}

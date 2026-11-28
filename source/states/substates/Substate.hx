package states.substates;

import cpp.vm.Gc;

class Substate extends flixel.FlxSubState {
	var lastVolume:Float = 1.0;
	var volumeTween:flixel.tweens.FlxTween;

	public function new() {
		super();
	}

	override public function create() {
		super.create();
	}

	override public function onFocusLost():Void {
		super.onFocusLost();
		if (volumeTween != null)
			volumeTween.cancel();
		lastVolume = FlxG.sound.volume;
		volumeTween = flixel.tweens.FlxTween.tween(FlxG.sound, {volume: lastVolume * 0.3}, 0.5);
	}

	override public function onFocus():Void {
		super.onFocus();
		if (volumeTween != null)
			volumeTween.cancel();
		volumeTween = flixel.tweens.FlxTween.tween(FlxG.sound, {volume: lastVolume}, 0.5);
	}

	override function destroy() {
		#if cpp
		Gc.run(true);
		Gc.compact();
		#end

		super.destroy();
	}
}

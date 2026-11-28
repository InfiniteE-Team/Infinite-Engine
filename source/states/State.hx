package states;

import cpp.vm.Gc;

class State extends flixel.FlxState {
	public function new() {
		super();
	}

	override public function create() {
		super.create();

		core.config.CursorConfig.refresh();
	}

	override function openSubState(substate:flixel.FlxSubState) {
		super.openSubState(substate);
	}

	override function closeSubState() {
		super.closeSubState();
	}

	var lastVolume:Float = 1.0;
	var volumeTween:flixel.tweens.FlxTween;

	override public function onFocusLost():Void {
		if (volumeTween == null || !volumeTween.active) {
			lastVolume = FlxG.sound.volume;
		}

		if (volumeTween != null)
			volumeTween.cancel();

		volumeTween = flixel.tweens.FlxTween.tween(FlxG.sound, {volume: lastVolume * 0.3}, 0.5);
	}

	override public function onFocus():Void {
		if (volumeTween != null)
			volumeTween.cancel();
		volumeTween = flixel.tweens.FlxTween.tween(FlxG.sound, {volume: lastVolume}, 0.5);
	}

	override function destroy() {
		if (volumeTween != null) {
			volumeTween.cancel();
			volumeTween.destroy();
			volumeTween = null;
		}
		core.assets.Paths.clearCache();

		super.destroy();
		#if cpp
		Gc.run(true);
		Gc.compact();
		#end

		core.audio.Sound.clearGlobalCache();
	}
}

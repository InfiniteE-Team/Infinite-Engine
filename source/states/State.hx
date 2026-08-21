package states;

import cpp.vm.Gc;
import core.rhythm.audio.Sound;

class State extends flixel.FlxState {
	private var tweenManager:flixel.tweens.FlxTween.FlxTweenManager;
	private var timerManager:flixel.util.FlxTimer.FlxTimerManager;

	public function new() {
		super();
	}

	override public function create() {
		super.create();
		tweenManager = new flixel.tweens.FlxTween.FlxTweenManager();
		timerManager = new flixel.util.FlxTimer.FlxTimerManager();

		add(tweenManager);
		add(timerManager);
	}

	override function openSubState(substate:flixel.FlxSubState) {
		super.openSubState(substate);
		tweenTimerPause(false);
	}

	function tweenTimerPause(active:Bool) {
		if (tweenManager != null)
			tweenManager.active = active;
		if (timerManager != null)
			timerManager.active = active;
	}

	override function closeSubState() {
		super.closeSubState();
		tweenTimerPause(true);
	}

	var lastVolume:Float = 1.0;
	var volumeTween:flixel.tweens.FlxTween;

	override public function onFocusLost():Void {
		tweenTimerPause(false);

		if (volumeTween == null || !volumeTween.active) {
			lastVolume = FlxG.sound.volume;
		}

		if (volumeTween != null)
			volumeTween.cancel();

		volumeTween = flixel.tweens.FlxTween.tween(FlxG.sound, {volume: lastVolume * 0.4}, 0.5);
	}

	override public function onFocus():Void {
		tweenTimerPause(true);

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

		super.destroy();
		#if cpp
		Gc.run(true);
		Gc.compact();
		#end

		if (tweenManager != null) {
			tweenManager.clear();
			tweenManager.destroy();
			tweenManager = null;
		}
		if (timerManager != null) {
			timerManager.clear();
			timerManager.destroy();
			timerManager = null;
		}

		Sound.clearGlobalCache();
	}
}

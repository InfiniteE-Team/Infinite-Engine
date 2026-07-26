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

		FlxG.signals.focusLost.add(onFocusLost);
		FlxG.signals.focusGained.add(onFocusGained);
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

	override function onFocusLost():Void {
		FlxG.sound.pause();
		tweenTimerPause(false);
	}

	function onFocusGained():Void {
		FlxG.sound.resume();
		tweenTimerPause(true);
	}

	override function destroy() {
		super.destroy();
		#if cpp
		Gc.run(true);
		Gc.compact();
		#end

		FlxG.signals.focusLost.remove(onFocusLost);
		FlxG.signals.focusGained.remove(onFocusGained);

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

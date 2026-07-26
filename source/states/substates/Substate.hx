package states.substates;

import cpp.vm.Gc;

class Substate extends flixel.FlxSubState {
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

	override function destroy() {
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

		super.destroy();
	}
}

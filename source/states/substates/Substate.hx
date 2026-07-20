package states.substates;

import cpp.vm.Gc;

class Substate extends flixel.FlxSubState {
	private var tweenManager:flixel.tweens.FlxTween.FlxTweenManager = new flixel.tweens.FlxTween.FlxTweenManager();
	private var timerManager:flixel.util.FlxTimer.FlxTimerManager = new flixel.util.FlxTimer.FlxTimerManager();

	public function new() {
		super();
	}

	override public function create() {
		super.create();
		FlxG.plugins.addPlugin(tweenManager);
		FlxG.plugins.addPlugin(timerManager);
	}

	override function destroy() {
		super.destroy();
		#if cpp
		Gc.run(true);
		Gc.compact();
		#end

		if (tweenManager != null) {
			FlxG.plugins.remove(tweenManager);
			tweenManager = null;
		}
		if (timerManager != null) {
			FlxG.plugins.remove(timerManager);
			timerManager = null;
		}
	}
}

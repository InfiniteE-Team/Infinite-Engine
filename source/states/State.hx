package states;
import cpp.vm.Gc;
import core.rhythm.audio.Sound;

class State extends flixel.FlxState {
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

	override function openSubState(substate:flixel.FlxSubState) {
		super.openSubState(substate);
		if (tweenManager != null)
			tweenManager.active = false;
		if (timerManager != null)
			timerManager.active = false;
	}

	override function closeSubState() {
		super.closeSubState();
		if (tweenManager != null)
			tweenManager.active = true;
		if (timerManager != null)
			timerManager.active = true;
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

		Sound.clearGlobalCache();
	}
}

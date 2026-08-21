package states.substates;

import cpp.vm.Gc;

class Substate extends flixel.FlxSubState {
	private var tweenManager:flixel.tweens.FlxTween.FlxTweenManager;
	private var timerManager:flixel.util.FlxTimer.FlxTimerManager;

	var lastVolume:Float = 1.0;
    var volumeTween:flixel.tweens.FlxTween;

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

	override public function onFocusLost():Void {
        super.onFocusLost();

        if (volumeTween == null || !volumeTween.active) {
            lastVolume = FlxG.sound.volume;
        }

        if (volumeTween != null)
            volumeTween.cancel();

        volumeTween = flixel.tweens.FlxTween.tween(FlxG.sound, {volume: lastVolume * 0.4}, 0.5);
    }

    override public function onFocus():Void {
        super.onFocus();

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

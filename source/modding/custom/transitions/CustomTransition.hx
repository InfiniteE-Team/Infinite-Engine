package modding.custom.transitions;

import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CustomTransition extends flixel.FlxSubState {
	var finishCallback:Void->Void;
	var transBlack:FlxSprite;
	var transIn:Bool = true;
	var duration:Float = 0.2;

	public function new(transIn:Bool, duration:Float = 0.2, ?callback:Void->Void) {
		super();
		this.transIn = transIn;
		this.duration = duration;
		this.finishCallback = callback;
	}

	override public function create() {
		super.create();

		persistentUpdate = true;
		persistentDraw = true;

		var cam:FlxCamera = (FlxG.cameras.list.length > 0) ? FlxG.cameras.list[FlxG.cameras.list.length - 1] : FlxG.camera;
		if (cam != null) {
			this.cameras = [cam];
		}

		var width:Int = FlxG.width;
		var height:Int = FlxG.height;

		transBlack = new FlxSprite().makeGraphic(width, height, FlxColor.BLACK);
		transBlack.scrollFactor.set();
		transBlack.alpha = transIn ? 1 : 0;
		add(transBlack);

		var targetAlpha:Float = transIn ? 0 : 1;

		FlxTween.tween(transBlack, {alpha: targetAlpha}, duration, {
			ease: FlxEase.linear,
			onComplete: function(twn:FlxTween) {
				transBlack.alpha = targetAlpha;
				
				if (finishCallback != null) {
					var cb = finishCallback;
					finishCallback = null;
					cb();
				}
				if (transIn) {
					close();
				}
			}
		});
	}

	override public function destroy() {
		finishCallback = null;
		super.destroy();
	}
}

package states.custom;

import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CustomTransition extends flixel.FlxSubState {
	var finishCallback:Void->Void;
	var transGradient:FlxSprite;
	var transBlack:FlxSprite;
	var transIn:Bool = true;
	var duration:Float = 0.45;

	public function new(transIn:Bool, duration:Float = 0.45, ?callback:Void->Void) {
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

		var colors = transIn ? [FlxColor.TRANSPARENT, FlxColor.BLACK] : [FlxColor.BLACK, FlxColor.TRANSPARENT];
		transGradient = FlxGradient.createGradientFlxSprite(width, height, colors);
		transGradient.scrollFactor.set();
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(width, height, FlxColor.BLACK);
		transBlack.scrollFactor.set();
		add(transBlack);

		transGradient.y = -height;
		updateBlackPosition();

		FlxTween.tween(transGradient, {y: height}, duration, {
			ease: FlxEase.linear,
			onUpdate: function(twn:FlxTween) {
				updateBlackPosition();
			},
			onComplete: function(twn:FlxTween) {
				if (finishCallback != null) {
					var cb = finishCallback;
					finishCallback = null;
					cb();
				}
				close();
			}
		});
	}

	private function updateBlackPosition():Void {
		if (transIn) {
			transBlack.y = transGradient.y + transGradient.height;
		} else {
			transBlack.y = transGradient.y - transBlack.height;
		}
	}

	override public function destroy() {
		finishCallback = null;
		super.destroy();
	}
}

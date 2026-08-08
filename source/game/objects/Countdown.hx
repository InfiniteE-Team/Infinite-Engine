package game.objects;

import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import core.assets.FunkinSprite;
import core.json.objects.CountdownData;

class Countdown extends flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup<FunkinSprite> {
	public var skipCountdown:Bool = false;
	public var curCountdown:String = 'default';
	public var countData:CountdownData;
	public var count:Int = -1;
	public var onComplete:Void->Void;

	var timer:FlxTimer;
	var activeTween:FlxTween;

	// the countdown for playstate
	public function new(x:Float = 0, y:Float = 0, curCountdown:String = 'default') {
		super(x, y);
		this.curCountdown = curCountdown;
		loadSprite();
	}

	function loadSprite() {
		var path:String = Paths.getPath('data/countdown/' + curCountdown, "json");
		countData = FormatJson.readJson(path);
	}

	public function onCountdown() {
		count++;

		if (countData == null || countData.countdown == null)
			return;

		if (count >= countData.countdown.length) {
			if (onComplete != null)
				onComplete();
			return;
		}

		var countStep = countData.countdown[count];
		if (countStep == null)
			return;

		if (countStep.sound != null && countStep.sound.path != null)
			core.json.extensions.AudioData.AudioConfig.playElementAudio(countStep.sound, 'gameplay/countdown/$curCountdown/');

		if (countStep.props != null && countStep.props.path != null) {
			var sprite:FunkinSprite = new FunkinSprite(0, 0, true);
			sprite.loadProps(countStep.props, 'game/countdown/$curCountdown');
			sprite.screenCenter();
			add(sprite);

			activeTween = FlxTween.tween(sprite, {alpha: 0}, core.rhythm.RhythmCore.crochet / 1000, {
				ease: flixel.tweens.FlxEase.cubeInOut,
				onComplete: function(twn:FlxTween) {
					activeTween = null;
					sprite.destroy();
				}
			});
		}

		timer = new FlxTimer().start(core.rhythm.RhythmCore.crochet / 1000, function(_) onCountdown());
	}

	public function pause() {
		if (timer != null && !timer.finished) {
			timer.active = false;
		}
		if (activeTween != null && activeTween.active) {
			activeTween.active = false;
		}
	}

	public function resume() {
		if (timer != null && !timer.finished) {
			timer.active = true;
		}
		if (activeTween != null) {
			activeTween.active = true;
		}
	}

	override public function destroy() {
		if (timer != null) {
			timer.cancel();
			timer = null;
		}
		if (activeTween != null) {
			activeTween.cancel();
			activeTween = null;
		}
		super.destroy();
	}
}

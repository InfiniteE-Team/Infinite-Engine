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

	var activeSound:flixel.sound.FlxSound;

	var timer:FlxTimer;
	var activeTween:FlxTween;

	// the countdown for playstate
	public function new(x:Float = 0, y:Float = 0, curCountdown:String = 'default') {
		super(x, y);
		this.curCountdown = curCountdown;
		loadSprite();
	}

	var imageFolder:String;

	function loadSprite() {
		imageFolder = 'game/countdown/$curCountdown';
		var skin = PlayState.instance?.noteController?.noteSkin;
		if (curCountdown == 'default' && skin != null) {
			var fromSkin:CountdownData = game.objects.sprites.notes.NoteSkins.read(skin, 'countdown');
			if (fromSkin != null) {
				countData = fromSkin;
				countData.soundFolder ??= 'gameplay/countdown/default/';
				var folder = game.objects.sprites.notes.NoteSkins.imageFolder(skin, 'countdown');
				imageFolder = StringTools.endsWith(folder, '/') ? folder.substr(0, folder.length - 1) : folder;
				return;
			}
		}
		countData = FormatJson.readJson(Paths.getPath('data/countdown/' + curCountdown, "json"));
	}

	public function onCountdown() {
		count++;

		#if HSCRIPT_ALLOWED
		@:privateAccess {
			if (PlayState.instance?.script != null)
				PlayState.instance.script.call('onCountdownTick', [count]);
		}
		#end

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
			activeSound = core.json.extensions.AudioData.AudioConfig.playElementAudio(countStep.sound, countData.soundFolder ?? 'gameplay/countdown/$curCountdown/');

		if (countStep.props != null && countStep.props.path != null) {
			var sprite:FunkinSprite = new FunkinSprite(0, 0, true);
			sprite.loadProps(countStep.props, imageFolder);
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

		if (timer != null && !timer.finished) {
			timer.cancel();
			timer = null;
		}
		timer = new FlxTimer().start(core.rhythm.RhythmCore.crochet / 1000, function(_) onCountdown());
	}

	public function pause() {
		if (activeSound != null)
			activeSound.pause();

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
		if (activeSound != null)
			activeSound.play();
		if (activeTween != null) {
			activeTween.active = true;
		}
	}

	override public function destroy() {
		if (timer != null) {
			timer.cancel();
			timer = null;
		}
		if (activeSound != null) {
			activeSound.stop();
			activeSound = null;
		}
		if (activeTween != null) {
			activeTween.cancel();
			activeTween = null;
		}
		super.destroy();
	}
}

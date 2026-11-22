package game.objects;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import core.assets.FunkinSprite;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

@:nullSafety
class PopUp extends flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer<FunkinSprite> {
	#if HSCRIPT_ALLOWED
	var scripRat:ScriptHandler;
	#end

	var comboPool:Array<FunkinSprite> = [];
	var numberPool:Array<FunkinSprite> = [];
	var missPool:Array<FunkinSprite> = [];
	var poolPaths:Map<FunkinSprite, String> = [];

	public var numberOffsetX:Float = 0;
	public var numberOffsetY:Float = 0;

	public var onNoteHitPlayer:Void->Void = () -> {};
	public var onNoteHitMiss:Void->Void = () -> {};

	public function new(x:Float = 0, y:Float = 0, script:ScriptHandler) {
		super(x, y);
		scrollFactor.set(0, 0);
		#if HSCRIPT_ALLOWED
		scripRat = script;
		#end
		onNoteHitPlayer = () -> onComboPopUp(PlayState.instance.playStateConfig.rating, game.PlayStateConfig.combo);
		onNoteHitMiss = onMissPopup;
	}

	public function onComboPopUp(comboName:String, combo:Int) {
		#if HSCRIPT_ALLOWED
		if (scripRat?.hasScripts && scripRat?.callCancellable('onComboPopUp', [comboName, combo]))
			return;
		#end

		killPoolInstant(comboPool);
		killPoolInstant(numberPool);

		var comboSprite = getFromPool(comboPool);

		var defaultPath = Paths.getPath('game/ui/popup/${game.PlayStateConfig.comboSkin}/$comboName', 'image');
		var skinData = getSkinData('rating', comboName);

		setupSprite(comboSprite, skinData != null && skinData.path != null ? skinData.path : defaultPath, skinData != null && skinData.scale != null ? skinData.scale : 0.62,
			this.x + (skinData != null && skinData.offsetX != null ? skinData.offsetX : -160),
			this.y + (skinData != null && skinData.offsetY != null ? skinData.offsetY : -90));

		#if HSCRIPT_ALLOWED
		if (scripRat?.hasScripts && scripRat?.call('onCustomComboAnimation', [comboSprite, comboName]) == true) {
			if (combo >= 10)
				onShowComboNumbers(combo);
			return;
		}
		#end

		playStandardPopupTween(comboSprite);

		if (combo >= 10)
			onShowComboNumbers(combo);
	}

	function onShowComboNumbers(combo:Int) {
		#if HSCRIPT_ALLOWED
		if (scripRat?.hasScripts && scripRat.callCancellable('onShowComboNumbers', [combo]))
			return;
		#end

		var comboStr = StringTools.lpad(Std.string(combo), "0", 3);
		var separatedScore = [];

		for (i in 0...comboStr.length)
			separatedScore.push(Std.parseInt(comboStr.charAt(i)));

		var daLoop = 0;
		for (i in separatedScore) {
			var numScore = getFromPool(numberPool);
			var digitStr = Std.string(i);

			var defaultPath = Paths.getPath('game/ui/popup/${game.PlayStateConfig.comboSkin}/nums/digit-$i', 'image');
			var skinDigit = getSkinData('number', digitStr);

			var spacing = skinDigit != null && skinDigit.spacing != null ? skinDigit.spacing : 32;

			setupSprite(numScore, skinDigit != null && skinDigit.path != null ? skinDigit.path : defaultPath, skinDigit != null && skinDigit.scale != null ? skinDigit.scale : 0.38,
				this.x
				+ (spacing * daLoop)
				+ (skinDigit != null && skinDigit.offsetX != null ? skinDigit.offsetX : -150)
				+ numberOffsetX,
				this.y
				+ (skinDigit != null && skinDigit.offsetY != null ? skinDigit.offsetY : 0)
				+ numberOffsetY);

			#if HSCRIPT_ALLOWED
			if (scripRat?.hasScripts && scripRat?.call('onCustomNumberAnimation', [numScore, i, daLoop]) == true) {
				daLoop++;
				continue;
			}
			#end

			playStandardPopupTween(numScore);
			daLoop++;
		}
	}

	public function onMissPopup() {
		#if HSCRIPT_ALLOWED
		if (scripRat?.hasScripts && scripRat.callCancellable('onMissPopup', []))
			return;
		#end

		killPoolInstant(missPool);

		var rating = getFromPool(missPool);
		var defaultPath = Paths.getPath('game/ui/popup/${game.PlayStateConfig.comboSkin}/miss', 'image');
		var skinData = getSkinData('miss', 'miss');

		setupSprite(rating, skinData != null && skinData.path != null ? skinData.path : defaultPath, skinData != null && skinData.scale != null ? skinData.scale : 0.62,
			this.x + (skinData != null && skinData.offsetX != null ? skinData.offsetX : -145),
			this.y + (skinData != null && skinData.offsetY != null ? skinData.offsetY : -90));

		#if HSCRIPT_ALLOWED
		if (scripRat?.hasScripts && scripRat?.call('onCustomMissAnimation', [rating]) == true)
			return;
		#end

		playStandardPopupTween(rating);
	}

	/**
	 * Configure the visibility, graphic, scale, and position of a sprite in a clean way.
	 */
	function setupSprite(sprite:FunkinSprite, assetPath:String, scaleMultiplier:Float, posX:Float, posY:Float) {
		sprite.alpha = 1;
		sprite.visible = true;

		if (poolPaths.get(sprite) != assetPath) {
			sprite.loadGraphic(assetPath);
			poolPaths.set(sprite, assetPath);
		}

		sprite.x = posX;
		sprite.y = posY;

		sprite.scale.set(1, 1);
		sprite.updateHitbox();
		sprite.setGraphicSize(Std.int(sprite.width * scaleMultiplier));
		sprite.updateHitbox();
	}

	/*
	 * Effect Bump
	 */
	function playStandardPopupTween(sprite:FunkinSprite) {
		var sx = sprite.scale.x * 1.15;
		var sy = sprite.scale.y * 1.15;

		FlxTween.tween(sprite.scale, {x: sx, y: sy}, 0.07, {
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				if (sprite == null || !sprite.alive)
					return;
				FlxTween.tween(sprite.scale, {x: sprite.scale.x / 1.15, y: sprite.scale.y / 1.15}, 0.10, {
					ease: FlxEase.quadIn
				});
			}
		});

		FlxTween.tween(sprite, {alpha: 0}, 0.20, {
			startDelay: 0.45,
			ease: FlxEase.quadIn,
			onComplete: function(_) {
				sprite.kill();
			}
		});
	}

	public function getSkinData(type:String, details:String):Dynamic {
		#if HSCRIPT_ALLOWED
		if (scripRat.hasScripts) {
			var result = scripRat.call('onSkinCombo', [type, details]);
			if (result != null && result != false)
				return result;
		}
		#end
		return game.PlayState.instance?.noteController?.popupImage(type, details);
	}

	public function killPoolInstant(pool:Array<FunkinSprite>) {
		for (sprite in pool) {
			if (sprite.exists && sprite.alive) {
				FlxTween.cancelTweensOf(sprite);
				FlxTween.cancelTweensOf(sprite.scale);
				sprite.alpha = 0;
				sprite.kill();
			}
		}
	}

	function getFromPool(pool:Array<FunkinSprite>) {
		for (sprite in pool) {
			if (!sprite.exists) {
				sprite.revive();
				return sprite;
			}
		}
		var newSprite = new FunkinSprite(0, 0, true);
		pool.push(newSprite);
		add(newSprite);
		return newSprite;
	}

	override public function destroy() {
		comboPool = [];
		numberPool = [];
		missPool = [];
		poolPaths.clear();

		super.destroy();
	}
}

package game.objects;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import core.assets.FunkinSprite;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

class Rating extends flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup<FunkinSprite> {
	#if HSCRIPT_ALLOWED
	var scripRat:ScriptHandler;
	#end
	// rating
	var ratingPool:Array<FunkinSprite> = [];
	var numberPool:Array<FunkinSprite> = [];
	var missPool:Array<FunkinSprite> = [];
	var poolPaths:Map<FunkinSprite, String> = [];

	public var onNoteHitPlayer:Void->Void;
	public var onNoteHitMiss:Void->Void;

	public var PIXEL_ZOOM:Float = 6;

	public var isPixel:Bool = false;

	public function new(x:Float = 0, y:Float = 0, script:ScriptHandler) {
		super(x, y);
		scrollFactor.set(0, 0);
		#if HSCRIPT_ALLOWED
		scripRat = script;
		#end
		onNoteHitPlayer = () -> onRatingPopUp(PlayState.instance.playStateConfig.rating, PlayState.instance.playStateConfig.combo);
		onNoteHitMiss = onMissPopup;
	}

	public function onRatingPopUp(ratingName:String, combo:Int) {
		#if HSCRIPT_ALLOWED
		if (scripRat?.hasScripts && scripRat?.callCancellable('onRatingPopUp', [ratingName, combo]))
			return;
		#end
		var pixelPart1 = 'normal/score/';
		var pixelPart2 = '';

		if (isPixel) {
			pixelPart1 = 'pixel/score/';
			pixelPart2 = '-pixel';
		}

		killPoolInstant(ratingPool);
		killPoolInstant(numberPool);

		var ratingSprite = getFromPool(ratingPool);
		ratingSprite.alpha = 1;
		ratingSprite.visible = true;

		var skinRating = getSkinRating('ratings', ratingName);
		if (skinRating != null) {
			if (poolPaths.get(ratingSprite) != skinRating.path) {
				ratingSprite.loadGraphic(skinRating.path);
				poolPaths.set(ratingSprite, skinRating.path);
			}
		} else {
			if (poolPaths.get(ratingSprite) != Paths.getPath('game/hud/' + pixelPart1 + ratingName + pixelPart2, 'image')) {
				ratingSprite.loadGraphic(Paths.getPath('game/hud/' + pixelPart1 + ratingName + pixelPart2, 'image'));
				poolPaths.set(ratingSprite, Paths.getPath('game/hud/' + pixelPart1 + ratingName + pixelPart2, 'image'));
			}
		}

		ratingSprite.x = this.x - 160;
		ratingSprite.y = this.y - 90;

		ratingSprite.scale.set(1, 1);
		ratingSprite.updateHitbox();
		if (!isPixel) {
			ratingSprite.setGraphicSize(Std.int(ratingSprite.width * 0.7));
		} else {
			ratingSprite.setGraphicSize(Std.int(ratingSprite.width * PIXEL_ZOOM * 0.7));
		}
		ratingSprite.updateHitbox();

		var sx = ratingSprite.scale.x * 1.15;
		var sy = ratingSprite.scale.y * 1.15;
		FlxTween.tween(ratingSprite.scale, {x: sx, y: sy}, 0.07, {
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				FlxTween.tween(ratingSprite.scale, {x: ratingSprite.scale.x / 1.15, y: ratingSprite.scale.y / 1.15}, 0.10, {ease: FlxEase.quadIn});
			}
		});

		FlxTween.tween(ratingSprite, {alpha: 0}, 0.20, {
			startDelay: 0.45,
			ease: FlxEase.quadIn,
			onComplete: function(_) {
				ratingSprite.kill();
			}
		});

		if (combo >= 10)
			onShowComboNumbers(combo, pixelPart1, pixelPart2);
	}

	function onShowComboNumbers(combo:Int, pixelPart1:String, pixelPart2:String) {
		#if HSCRIPT_ALLOWED
		if (scripRat.hasScripts && scripRat.callCancellable('onShowComboNumbers', [combo, pixelPart1, pixelPart2]))
			return;
		#end
		var comboStr = StringTools.lpad(Std.string(combo), "0", 3);
		var separatedScore = [];

		for (i in 0...comboStr.length)
			separatedScore.push(Std.parseInt(comboStr.charAt(i)));

		var daLoop = 0;
		for (i in separatedScore) {
			var numScore = getFromPool(numberPool);
			numScore.alpha = 1;
			numScore.visible = true;
			var skinDigit = getSkinRating('numbers', Std.string(Std.int(i)));
			if (skinDigit != null) {
				if (poolPaths.get(numScore) != skinDigit.path) {
					numScore.loadGraphic(skinDigit.path);
					poolPaths.set(numScore, skinDigit.path);
				}
			} else {
				if (poolPaths.get(numScore) != Paths.getPath('game/hud/' + pixelPart1 + 'nums/digit-' + Std.int(i) + pixelPart2, 'image')) {
					numScore.loadGraphic(Paths.getPath('game/hud/' + pixelPart1 + 'nums/digit-' + Std.int(i) + pixelPart2, 'image'));
					poolPaths.set(numScore, Paths.getPath('game/hud/' + pixelPart1 + 'nums/digit-' + Std.int(i) + pixelPart2, 'image'));
				}
			}

			numScore.x = this.x + (32 * daLoop) - 90;
			numScore.y = this.y + 20;

			numScore.scale.set(1, 1);
			numScore.updateHitbox();
			if (!isPixel) {
				numScore.setGraphicSize(Std.int(numScore.width * 0.38));
			} else {
				numScore.setGraphicSize(Std.int(numScore.width * 5.4));
			}
			numScore.updateHitbox();

			FlxTween.tween(numScore, {"scale.x": numScore.scale.x * 1.15, "scale.y": numScore.scale.y * 1.15}, 0.07, {
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					FlxTween.tween(numScore, {"scale.x": numScore.scale.x / 1.15, "scale.y": numScore.scale.y / 1.15}, 0.10, {
						ease: FlxEase.quadIn
					});
				}
			});
			FlxTween.tween(numScore, {alpha: 0}, 0.20, {
				startDelay: 0.45,
				ease: FlxEase.quadIn,
				onComplete: function(_) {
					numScore.kill();
				}
			});
			daLoop++;
		}
	}

	public function getSkinRating(type:String, details:String):Dynamic {
		#if HSCRIPT_ALLOWED
		if (scripRat.hasScripts) {
			var result = scripRat.call('onSkinRating', [type, details]);
			if (result != null && result != false)
				return result;
		}
		#end
		return game.PlayState.instance?.noteController?.popupImage(type, details);
	}

	public function onMissPopup() {
		#if HSCRIPT_ALLOWED
		if (scripRat.hasScripts && scripRat.callCancellable('onMissPopup', []))
			return;
		#end
		killPoolInstant(missPool);

		var rating = getFromPool(missPool);
		rating.alpha = 1;
		rating.visible = true;

		if (isPixel) {
			if (poolPaths.get(rating) != Paths.getPath('game/hud/pixel/score/miss-pixel', 'image')) {
				rating.loadGraphic(Paths.getPath('game/hud/pixel/score/miss-pixel', 'image'));
				poolPaths.set(rating, Paths.getPath('game/hud/pixel/score/miss-pixel', 'image'));
			}
		} else {
			if (poolPaths.get(rating) != Paths.getPath('game/hud/normal/score/miss', 'image')) {
				rating.loadGraphic(Paths.getPath('game/hud/normal/score/miss', 'image'));
				poolPaths.set(rating, Paths.getPath('game/hud/normal/score/miss', 'image'));
			}
		}

		rating.x = this.x - 145;
		rating.y = this.y - 90;

		rating.scale.set(1, 1);
		rating.updateHitbox();
		if (!isPixel) {
			rating.setGraphicSize(Std.int(rating.width * 0.7));
		} else {
			rating.setGraphicSize(Std.int(rating.width * PIXEL_ZOOM * 0.7));
		}
		rating.updateHitbox();

		// Bump appears
		FlxTween.tween(rating, {"scale.x": rating.scale.x * 1.15, "scale.y": rating.scale.y * 1.15}, 0.07, {
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				FlxTween.tween(rating, {"scale.x": rating.scale.x / 1.15, "scale.y": rating.scale.y / 1.15}, 0.10, {
					ease: FlxEase.quadIn
				});
			}
		});
		FlxTween.tween(rating, {alpha: 0}, 0.20, {
			startDelay: 0.45,
			ease: FlxEase.quadIn,
			onComplete: function(_) {
				rating.kill();
			}
		});
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
		for (s in ratingPool) {
			remove(s);
			s.destroy();
		}
		for (s in numberPool) {
			remove(s);
			s.destroy();
		}
		for (s in missPool) {
			remove(s);
			s.destroy();
		}
		ratingPool = [];
		numberPool = [];
		missPool = [];
		super.destroy();
	}
}

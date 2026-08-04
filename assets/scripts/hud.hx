import utils.InfiniteUtil;
import flixel.util.FlxStringUtil;
import flixel.text.FlxTextBorderStyle;

var scoreText:FlxText;
var ratingPool = [];
var numberPool = [];
var comboPool = [];
var missPool = [];

function postCreate() {
	scoreText = new FlxText(0, healthBarY + 30, FlxG.width, "Score: 0 / Misses: 0");
	scoreText.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFFFFFFFF, "center");
	scoreText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
	scoreText.antialiasing = SaveData.data.antialiasing;
	scoreText.scrollFactor.set(0, 0);
	scoreText.cameras = [camHUD];
	add(scoreText);
}

function postUpdate(elapsed:Float) {
	updateScore();
}

function updateScore() {
	var scoreFinal:String = InfiniteUtil.formatNumber(playStateConfig.score);
	scoreText.text = 'Score: $scoreFinal / Misses: ${playStateConfig.misses}';
}

function onRewind() {
	ratingPool = [];
	comboPool = [];
	numberPool = [];
	missPool = [];
}

function onDestroy() {
	ratingPool = [];
	comboPool = [];
	numberPool = [];
	missPool = [];
	scoreText.destroy();
}

var PIXEL_ZOOM = 6;
var isPixel = false;

function onNoteHitPlayer() {
	onRatingPopup(playStateConfig.rating, playStateConfig.combo);
}

function onNoteHitMiss() {
	onMissPopup();
}

function onRatingPopup(ratingName, combo) {
	var pixelPart1 = 'normal/score/';
	var pixelPart2 = '';

	if (isPixel) {
		pixelPart1 = 'pixel/score/';
		pixelPart2 = '-pixel';
	}

	_killPoolInstant(ratingPool);
	_killPoolInstant(numberPool);

	var ratingSprite = _getFromPool(ratingPool);
	ratingSprite.alpha = 1;
	ratingSprite.visible = true;

	ratingSprite.loadGraphic(Paths.getPath('game/hud/' + pixelPart1 + ratingName + pixelPart2, 'image'));

	ratingSprite.x = FlxG.width * 0.55 - 160;
	ratingSprite.y = FlxG.height * 0.5 - 90;

	if (!isPixel) {
		ratingSprite.setGraphicSize(Std.int(ratingSprite.width * 0.7));
		ratingSprite.antialiasing = SaveData.data.antialiasing;
	} else {
		ratingSprite.setGraphicSize(Std.int(ratingSprite.width * PIXEL_ZOOM * 0.7));
		ratingSprite.antialiasing = false;
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
		_showComboNumbers(combo, pixelPart1, pixelPart2);
}

function _showComboNumbers(combo, pixelPart1, pixelPart2) {
	var comboStr = Std.string(combo);
	var separatedScore = [];

	for (i in 0...comboStr.length)
		separatedScore.push(Std.parseInt(comboStr.charAt(i)));

	var daLoop = 0;
	for (i in separatedScore) {
		var numScore = _getFromPool(numberPool);
		numScore.alpha = 1;
		numScore.visible = true;
		numScore.loadGraphic(Paths.getPath('game/hud/' + pixelPart1 + 'nums/num' + Std.int(i) + pixelPart2, 'image'));

		numScore.x = FlxG.width * 0.55 + (43 * daLoop) - 90 + 20;
		numScore.y = FlxG.height * 0.5 + 20;

		if (!isPixel) {
			numScore.antialiasing = SaveData.data.antialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * 0.35));
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

function onMissPopup() {
	_killPoolInstant(missPool);

	var rating = _getFromPool(missPool);
	rating.alpha = 1;
	rating.visible = true;

	if (isPixel)
		rating.loadGraphic(Paths.getPath('game/hud/pixel/score/miss-pixel', 'image'));
	else
		rating.loadGraphic(Paths.getPath('game/hud/normal/score/miss', 'image'));

	rating.x = FlxG.width * 0.55 - 40;
	rating.y = FlxG.height * 0.5 - 90;

	if (!isPixel) {
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.antialiasing = SaveData.data.antialiasing;
	} else {
		rating.setGraphicSize(Std.int(rating.width * PIXEL_ZOOM * 0.7));
		rating.antialiasing = false;
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

function _killPoolInstant(pool) {
	for (sprite in pool) {
		if (sprite.exists && sprite.alive) {
			FlxTween.cancelTweensOf(sprite);
			FlxTween.cancelTweensOf(sprite.scale);
			sprite.alpha = 0;
			sprite.kill();
		}
	}
}

function _getFromPool(pool) {
	for (sprite in pool) {
		if (!sprite.exists) {
			sprite.revive();
			return sprite;
		}
	}

	var newSprite = new FlxSprite();
	newSprite.cameras = [camHUD];
	newSprite.scrollFactor.set(0, 0);
	pool.push(newSprite);
	add(newSprite);
	return newSprite;
}

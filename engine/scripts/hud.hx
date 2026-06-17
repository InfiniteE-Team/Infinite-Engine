import core.assets.Paths;
import flixel.util.FlxStringUtil;
import flixel.text.FlxTextBorderStyle;

var playerIcon = null;
var opponentIcon = null;
var healthBarBG = null;
var healthBarFill = null;
var playerBumpScale = 1.0;
var opponentBumpScale = 1.0;
var BUMP_SCALE = 1.2;
var scoreText:FlxText;
var ratingPool = [];
var numberPool = [];
var comboPool = [];
var missPool = [];

function onCreate() {
	var healthBarY = SaveData.data.downscroll ? FlxG.height * 0.1 : FlxG.height * 0.88;

	healthBarBG = new FlxSprite(0, healthBarY);
	healthBarBG.loadGraphic(Paths.getPath('game/hud/healthBar', 'image'));
	healthBarBG.scrollFactor.set(0, 0);
	healthBarBG.cameras = [camHUD];
	healthBarBG.x = (FlxG.width - healthBarBG.width) * 0.5;
	healthBarBG.antialiasing = true;
	add(healthBarBG);

	scoreText = new FlxText(0, healthBarBG.y + 30, FlxG.width, "Score: 0 - Misses: 0");
	scoreText.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFFFFFFFF, "center");
	scoreText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
	scoreText.antialiasing = true;
	scoreText.scrollFactor.set(0, 0);
	scoreText.cameras = [camHUD];
	add(scoreText);

	healthBarFill = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, LEFT_TO_RIGHT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8),
		playStateConfig, 'health', 0, 2);
	healthBarFill.scrollFactor.set(0, 0);
	healthBarFill.flipX = true;
	healthBarFill.cameras = [camHUD];

	var dadColor = 0xFFFF0000;
	var bfColor = 0xFF66FF33;
	for (charData in PlayState.SONG.chars) {
		var char = chars.get(charData.id);
		if (char == null)
			continue;
		var isPlayer = game.controllers.CharacterController.namesPlayer.contains(charData.role);
		var isOpponent = game.controllers.CharacterController.namesOpponent.contains(charData.role);
		if (isPlayer && char.charData.healthBarColor != null)
			bfColor = char.charData.healthBarColor;
		if (isOpponent && char.charData.healthBarColor != null)
			dadColor = char.charData.healthBarColor;
	}
	healthBarFill.createFilledBar(dadColor, bfColor);
	add(healthBarFill);

	for (charData in PlayState.SONG.chars) {
		var char = chars.get(charData.id);
		if (char == null)
			continue;
		var isPlayer = game.controllers.CharacterController.namesPlayer.contains(charData.role);
		var isOpponent = game.controllers.CharacterController.namesOpponent.contains(charData.role);
		if (!isPlayer && !isOpponent)
			continue;
		var icon = new game.objects.sprites.Icon(isPlayer, char.charData);
		icon.cameras = [camHUD];
		icon.scrollFactor.set(0, 0);
		add(icon);
		if (isPlayer)
			playerIcon = icon;
		else
			opponentIcon = icon;
	}

	_updateIconPositions();
}

function postUpdate(elapsed:Float) {
	updateScore();
	_updateLosingAnim();
	_updateIconPositions();
	_lerpBumpScale(elapsed);
}

function updateScore() {
	var scoreFinal:String = FlxStringUtil.formatMoney(playStateConfig.score, false);
	scoreText.text = 'Score: $scoreFinal - Misses: ${playStateConfig.misses}';
}

function postBeatHit(beat:Float) {
	if (playerIcon != null && playerIcon.bumpInBeats) {
		var tempo = playerIcon.stepTempo > 0 ? playerIcon.stepTempo : 1;
		if (beat % tempo == 0)
			playerBumpScale = BUMP_SCALE;
	}

	if (opponentIcon != null && opponentIcon.bumpInBeats) {
		var tempo = opponentIcon.stepTempo > 0 ? opponentIcon.stepTempo : 1;
		if (beat % tempo == 0)
			opponentBumpScale = BUMP_SCALE;
	}
}

function onDestroy() {
	playerIcon = null;
	opponentIcon = null;
	healthBarBG = null;
	healthBarFill = null;

	ratingPool = [];
	comboPool = [];
	numberPool = [];
	missPool = [];
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

	ratingSprite.loadGraphic(Paths.getPath('game/hud/' + pixelPart1 + ratingName + pixelPart2,'image'));

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
		numScore.loadGraphic(Paths.getPath('game/hud/' + pixelPart1 + 'nums/num' + Std.int(i) + pixelPart2,'image'));

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
		rating.loadGraphic(Paths.getPath('game/hud/pixel/score/miss-pixel','image'));
	else
		rating.loadGraphic(Paths.getPath('game/hud/normal/score/miss','image'));

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

function _updateLosingAnim() {
	var health = playStateConfig.health;

	if (playerIcon != null) {
		var losing = health < 0.4;
		playerIcon.playAnim(losing ? 'losing' : 'normal');
	}

	if (opponentIcon != null) {
		var losing = health > 1.6;
		opponentIcon.playAnim(losing ? 'losing' : 'normal');
	}
}

function _updateIconPositions() {
	if (healthBarBG == null)
		return;

	var ratio = Math.max(0, Math.min(playStateConfig.health / 2.0, 1.0));
	var barCenterX = healthBarBG.x + healthBarBG.width * ratio;

	if (playerIcon != null) {
		playerIcon.x = barCenterX - playerIcon.width * 0.5 - 4;
		playerIcon.y = healthBarBG.y - playerIcon.height * 0.5;
	}

	if (opponentIcon != null) {
		opponentIcon.x = barCenterX - opponentIcon.width * 0.5 + 4;
		opponentIcon.y = healthBarBG.y - opponentIcon.height * 0.5;
	}
}

function _lerpBumpScale(elapsed:Float) {
	var speed = elapsed * 12;

	playerBumpScale = playerBumpScale + (1.0 - playerBumpScale) * speed;
	opponentBumpScale = opponentBumpScale + (1.0 - opponentBumpScale) * speed;

	if (playerIcon != null) {
		playerIcon.scale.set(playerBumpScale, playerBumpScale);
		playerIcon.updateHitbox();
	}

	if (opponentIcon != null) {
		opponentIcon.scale.set(opponentBumpScale, opponentBumpScale);
		opponentIcon.updateHitbox();
	}
}
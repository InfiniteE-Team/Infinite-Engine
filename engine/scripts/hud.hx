import core.assets.Paths;

var playerIcon = null;
var opponentIcon = null;
var healthBarBG = null;
var healthBarFill = null;
var playerBumpScale = 1.0;
var opponentBumpScale = 1.0;
var BUMP_SCALE = 1.2;

function onCreate() {
	var healthBarY = saveData.downscroll ? FlxG.height * 0.1 : FlxG.height * 0.88;

	healthBarBG = new FlxSprite(0, healthBarY);
	healthBarBG.loadGraphic(Paths.getPath('game/hud/healthBar', 'image'));
	healthBarBG.scrollFactor.set(0, 0);
	healthBarBG.cameras = [camHUD];
	healthBarBG.x = (FlxG.width - healthBarBG.width) * 0.5;
	healthBarBG.antialiasing = true;
	add(healthBarBG);

	healthBarFill = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, LEFT_TO_RIGHT, Std.int(healthBarBG.width - 8),
		Std.int(healthBarBG.height - 8), playStateConfig, 'health', 0, 2);
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
	//_updateHealthBar();
	_updateLosingAnim();
	_updateIconPositions();
	_lerpBumpScale(elapsed);
}

function onBeatHit(beat:Float) {
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
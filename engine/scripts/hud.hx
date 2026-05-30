var playerIcon = null;
var opponentIcon = null;
var healthBarBG = null;
var healthBarFill = null;
var playerBumpScale = 1.0;
var opponentBumpScale = 1.0;
var BUMP_SCALE = 1.2;

function postCreate() {
	var state = PlayState.instance;

	var barW = 600;
	var barH = 20;
	var barY = FlxG.height - 34;
	var barX = (FlxG.width - barW) / 2;

	healthBarBG = new FlxSprite(barX, barY);
	healthBarBG.makeGraphic(barW, barH, 0xFF000000);
	healthBarBG.cameras = [state.camHUD];
	healthBarBG.scrollFactor.set(0, 0);
	add(healthBarBG);

	healthBarFill = new FlxSprite(barX + 2, barY + 2);
	healthBarFill.makeGraphic(barW - 4, barH - 4, 0xFFFF0000);
	healthBarFill.cameras = [state.camHUD];
	healthBarFill.scrollFactor.set(0, 0);
	add(healthBarFill);

	for (charData in PlayState.SONG.chars) {
		var char = state.chars.get(charData.id);
		if (char == null)
			continue;

		var isPlayer = game.controllers.CharacterController.namesPlayer.contains(charData.role);
		var isOpponent = game.controllers.CharacterController.namesOpponent.contains(charData.role);

		if (!isPlayer && !isOpponent)
			continue;

		var icon = new game.objects.sprites.Icon(isPlayer, char.charData);
		icon.cameras = [state.camHUD];
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
	_updateHealthBar();
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

function _updateHealthBar() {
	if (healthBarFill == null)
		return;

	var ratio = Math.max(0, Math.min(PlayState.instance.health / 2.0, 1.0));
	var maxW = healthBarBG.width - 4;

	healthBarFill.scale.x = ratio;
	healthBarFill.offset.x = -(maxW * (1.0 - ratio)) / 2.0;
}

function _updateLosingAnim() {
	var health = PlayState.instance.playStateConfig.health;

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

	var ratio = Math.max(0, Math.min(PlayState.instance.playStateConfig.health / 2.0, 1.0));
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

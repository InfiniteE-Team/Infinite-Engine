package game.controllers;

import game.PlayState;
import game.objects.Bar;
import core.assets.FunkinSprite;
import game.objects.sprites.Icon;

class HUDController extends flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxBasic> {
	public var iconP1:Icon;
	public var iconP2:Icon;
	public var healthBarBG:FunkinSprite;
	public var healthBar:Bar;
	public var healthBarY:Float = 0;

	public function new() {
		super();
		createHUD();
	}

	public function createHUD() {
		healthBarY = core.config.SaveData.data.downscroll ? FlxG.height * 0.1 : FlxG.height * 0.88;

		healthBarBG = new FunkinSprite(0, healthBarY, true);
		healthBarBG.loadGraphic(Paths.getPath('game/hud/healthBar', 'image'));
		healthBarBG.scrollFactor.set(0, 0);
		healthBarBG.x = (FlxG.width - healthBarBG.width) * 0.5;
		healthBarBG.antialiasing = SaveData.data.antialiasing;
		add(healthBarBG);

		healthBar = new Bar(healthBarBG.x + 4, healthBarBG.y + 4, PlayState.instance.playStateConfig.health, 'LEFT_TO_RIGHT', 2);
		healthBar.scrollFactor.set(0, 0);

		var dadColor = 0xFFFF0000;
		var bfColor = 0xFF66FF33;
		for (charData in PlayState.SONG.chars) {
			var char = cast(PlayState.instance.chars.get(charData.id));
			if (char == null)
				continue;
			var isPlayer = game.controllers.CharacterController.namesPlayer.contains(charData.role);
			var isOpponent = game.controllers.CharacterController.namesOpponent.contains(charData.role);
			if (isPlayer && char.characterData.icon.healthBarColor != null)
				bfColor = flixel.util.FlxColor.fromString(char.characterData.icon.healthBarColor);
			if (isOpponent && char.characterData.icon.healthBarColor != null)
				dadColor = flixel.util.FlxColor.fromString(char.characterData.icon.healthBarColor);
		}
		healthBar.createFilledBar([dadColor, bfColor]);
		add(healthBar);

		for (charData in PlayState.SONG.chars) {
			var char = cast(PlayState.instance.chars.get(charData.id));
			if (char == null)
				continue;
			var isPlayer = game.controllers.CharacterController.namesPlayer.contains(charData.role);
			var isOpponent = game.controllers.CharacterController.namesOpponent.contains(charData.role);
			if (!isPlayer && !isOpponent)
				continue;
			var icon = new game.objects.sprites.Icon(isPlayer, char.characterData);
			icon.scrollFactor.set(0, 0);
			add(icon);

			if (isPlayer)
				iconP1 = icon;
			else
				iconP2 = icon;
		}
		_updateIconPositions(0.016);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (PlayState.instance == null || PlayState.instance.playStateConfig == null)
			return;

		if (healthBar != null)
			healthBar.argument = PlayState.instance.playStateConfig.health;

		if (iconP1 == null && iconP2 == null)
			return;

		for (icon in [iconP1, iconP2]) {
			if (icon.scale.x > 1.0) {
				icon.scale.x = flixel.math.FlxMath.lerp(icon.scale.x, 1.0, elapsed * 12);
				icon.scale.y = flixel.math.FlxMath.lerp(icon.scale.y, 1.0, elapsed * 12);
			}
		}

		_updateLosingAnim();
		_updateIconPositions(elapsed);
	}

	function _updateLosingAnim() {
		if (iconP1 != null) {
			var losing = PlayState.instance.playStateConfig.health < 0.4;
			iconP1.playAnim(losing ? 'losing' : 'normal');
		}

		if (iconP2 != null) {
			var losing = PlayState.instance.playStateConfig.health > 1.6;
			iconP2.playAnim(losing ? 'losing' : 'normal');
		}
	}

	function _updateIconPositions(elapsed:Float = 0.016) {
		if (healthBarBG == null)
			return;

		var ratio = 1.0 - Math.max(0, Math.min(PlayState.instance.playStateConfig.health / 2.0, 1.0));
		var centerX = healthBarBG.x + healthBarBG.width * ratio;
		var lerpVal = Math.max(0, Math.min(1, elapsed * 12));

		var icons = [iconP1, iconP2];
		var offsets = [55, -55];

		for (i in 0...icons.length) {
			var icon = icons[i];
			if (icon == null)
				continue;

			var targetX = centerX - icon.width * 0.5 + offsets[i];
			var targetY = healthBarBG.y - icon.height * 0.5;

			icon.x = flixel.math.FlxMath.lerp(icon.x, targetX, lerpVal);
			icon.y = targetY;
		}
	}

	public function beatHit(beat:Float) {
		if (iconP1 == null && iconP2 == null)
			return;
		for (icon in [iconP1, iconP2]) {
			if (icon.bumpInBeats && Math.floor(beat % icon.stepTempo) == 0)
				icon.scale.set(1.2, 1.2);
		}
	}

	override function destroy() {
		super.destroy();
		iconP1 = null;
		iconP2 = null;
		healthBarBG = null;
		healthBar = null;
	}
}

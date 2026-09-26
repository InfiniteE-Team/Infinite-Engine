package game.controllers;

import game.PlayState;
import game.objects.Bar;
import flixel.text.FlxText;
import core.assets.FunkinSprite;
import game.objects.sprites.Icon;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

class HUDController extends flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxBasic> {
	#if HSCRIPT_ALLOWED
	var scriptHUD:ScriptHandler;
	#end

	static inline var barYNORMAL:Float = 0.88;
	static inline var barYDOWNSCROLL:Float = 0.10;

	public var iconP1:Icon;
	public var iconP2:Icon;
	public var healthBarBG:FunkinSprite;
	public var healthBar:Bar;
	public var healthBarY:Float = 0;
	public var scoreText:FlxText;

	var intendedScore:Float = 0;

	public function new(script:ScriptHandler) {
		super();
		#if HSCRIPT_ALLOWED
		scriptHUD = script;
		#end
		createHUD();
	}

	public function createHUD() {
		#if HSCRIPT_ALLOWED
		scriptHUD.call("onCreateHUD", []);
		#end
		healthBarY = FlxG.height * (core.config.SaveData.data.downscroll ? barYDOWNSCROLL : barYNORMAL);

		healthBarBG = new FunkinSprite(0, healthBarY + 5, true);
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

		scoreText = new FlxText(0, healthBarY + 30, FlxG.width, "Score: 0 // Combo Breaks: 0");
		scoreText.setFormat(Paths.getPath('Funkin.otf', 'font'), 20, 0xFFFFFFFF, "center");
		scoreText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		scoreText.antialiasing = SaveData.data.antialiasing;
		scoreText.scrollFactor.set(0, 0);
		add(scoreText);

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
		#if HSCRIPT_ALLOWED
		scriptHUD.call("postCreateHUD", []);
		#end
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		updateScore(elapsed);

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

	function updateScore(elapsed:Float) {
		intendedScore = flixel.math.FlxMath.lerp(intendedScore, PlayState.instance.playStateConfig.score, flixel.math.FlxMath.bound(elapsed * 16, 0, 1));

		var displayScore:String = InfiniteUtil.formatNumber(Math.round(intendedScore));

		if (SaveData.data.botplay)
			scoreText.text = 'BOTPLAY';
		else
			scoreText.text = 'Score: $displayScore // Combo Breaks: ${PlayState.instance.playStateConfig.misses}';
	}

	public function applyDownscroll(newDownscroll:Bool):Void {
		healthBarY = FlxG.height * (newDownscroll ? barYDOWNSCROLL : barYNORMAL);
		if (scoreText != null)
			scoreText.y = healthBarY + 30;
		if (healthBarBG != null)
			healthBarBG.y = healthBarY;
		if (healthBar != null)
			healthBar.y = healthBarY + 4;

		#if HSCRIPT_ALLOWED
		scriptHUD.call("postApplyDownscrollHUD", [newDownscroll]);
		#end
	}

	function _updateLosingAnim():Null<Dynamic> {
		#if HSCRIPT_ALLOWED
		if (scriptHUD.hasScripts && scriptHUD.callCancellable('onIconAnim', []))
			return null;
		#end

		if (iconP1 != null) {
			var losing = PlayState.instance.playStateConfig.health < 0.4;
			iconP1.playAnim(losing ? 'losing' : 'normal');
		}

		if (iconP2 != null) {
			var losing = PlayState.instance.playStateConfig.health > 1.6;
			iconP2.playAnim(losing ? 'losing' : 'normal');
		}

		#if HSCRIPT_ALLOWED
		scriptHUD.call("postIconAnim", []);
		#end

		return null;
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
		scoreText.destroy();
		scoreText = null;
		iconP1 = null;
		iconP2 = null;
		healthBarBG = null;
		healthBar = null;
	}
}

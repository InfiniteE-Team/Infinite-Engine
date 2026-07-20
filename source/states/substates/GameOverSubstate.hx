package states.substates;

import game.PlayState;
import flixel.tweens.FlxTween;
import core.json.objects.CharacterData;
import game.objects.sprites.Character;

class GameOverSubstate extends MusicBeatSubstate {
	var char:Character = null;
	var gameOverData:CharacterData;

	var sound:String = '';
	var endAnim:String = '';

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		var bg:flixel.FlxSprite = new flixel.FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set(0, 0);
		bg.alpha = 0;
		add(bg);

		FlxTween.tween(bg, {alpha: 1}, 3);

		for (data in PlayState.SONG.chars) {
			var isPlayer = game.controllers.CharacterController.namesPlayer.contains(data.role);

			if (!isPlayer)
				continue;

			var charYep = cast(PlayState.instance.chars.get(data.id));

			gameOverData = FormatJson.readJson(Paths.getPath('data/characters/' + data.name, 'json'));

			char = new Character(data.id, gameOverData.gameplay.death.character, charYep.x, charYep.y);

			PlayState.instance.cameraController.followChar(char);

			sound = gameOverData.gameplay.death.sound;
			endAnim = gameOverData.gameplay.death.endAnim;

			break;
		}

		if (char == null)
			return;

		add(char);

		char.playAnim('firstDeath');
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (char.isFinished('firstDeath') && !char.currentAnim.startsWith('firstDeath'))
			char.playAnim('deathLoop', true);

		if (input.control.justPressedAction("uiKeys", 'accept'))
			char.playAnim('deathConfirm', true);
	}
}

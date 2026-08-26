package states.substates;

import game.PlayState;
import flixel.tweens.FlxTween;
import core.json.objects.CharacterData;
import game.objects.sprites.Character;

class GameOverSubstate extends MusicBeatSubstate {
	var char:Character = null;
	var gameOverData:CharacterData;

	var sound:String = '';
	var music:String = '';
	var endSound:String = '';

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		#if HSCRIPT_ALLOWED
		script.call("onCreate", []);
		#end

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

			var deathCharName:String = (gameOverData != null && gameOverData.gameplay != null && gameOverData.gameplay.death != null) ? gameOverData.gameplay.death.character : data.name;

			char = new Character(data.id, deathCharName, charYep.x, charYep.y);

			if (PlayState.instance.cameraController != null)
				PlayState.instance.cameraController.followChar(char);

			if (gameOverData != null && gameOverData.gameplay != null && gameOverData.gameplay.death != null) {
				sound = gameOverData.gameplay.death?.sound ?? 'default/fnf_loss_sfx';
				music = gameOverData.gameplay.death?.music ?? 'default/gameOver';
				endSound = gameOverData.gameplay.death?.endSound ?? 'default/gameOverEnd';
			}

			break;
		}

		if (char == null) {
			Trace.traceOnce("ERROR: Character GameOver not loaded");
			return;
		}
		add(char);

		FlxG.sound.play(Paths.getPath('gameplay/death/' + sound, 'sound'));

		char.playAnim('firstDeath');

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		script.call("onUpdate", []);
		#end

		if (char.isFinished('firstDeath')) {
			char.playAnim('deathLoop', true);
			FlxG.sound.playMusic(Paths.getPath('gameplay/death/' + music, 'music'));
		}

		if (Controls.ACCEPT) {
			char.playAnim('deathConfirm', true);
			FlxG.sound.music?.stop();
			FlxG.sound.play(Paths.getPath('gameplay/death/' + endSound, 'music'));

			new flixel.util.FlxTimer().start(0.7, function(_) {
				FlxG.camera.fade(flixel.util.FlxColor.BLACK, 2, false, function() {
					close();
					MusicBeatState.resetState();
				});
			});
		}

		if (Controls.BACK) {
			FlxG.sound.music?.stop();
			close();
			#if HSCRIPT_ALLOWED
			script.call("onBack", []);
			#end
		}

		#if HSCRIPT_ALLOWED
		script.call("postUpdate", []);
		#end
	}
}

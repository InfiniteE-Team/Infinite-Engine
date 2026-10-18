package states.substates;

import game.PlayState;
import flixel.tweens.FlxTween;
import core.json.objects.CharacterData;
import game.objects.sprites.Character;

class GameOverSubstate extends MusicBeatSubstate {
	var char:Character = null;
	var gameOverData:CharacterData;

	var sound:String = 'default/fnf_loss_sfx';
	var music:String = 'default/gameOver';
	var endSound:String = 'default/gameOverEnd';

	var confirm:Bool = false;

	public function new() {
		super();
	}

	override public function create() {
		super.create();
		funkin.play.GameOverSubState.instance = new funkin.play.GameOverSubState(this);

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

			if (charYep == null) {
				trace('[GameOverSubstate] WARNING: char "${data.id}" not found in PlayState.chars');
				continue;
			}

			gameOverData = modding.vslice.VSliceCharacters.readCharacter(Paths.getPath('data/characters/' + data.name, 'json'));

			var deathCharName:String = (gameOverData != null && gameOverData.gameplay != null && gameOverData.gameplay.death != null) ? gameOverData.gameplay.death.character : data.name;

			char = new Character(data.id, deathCharName);
			char.isPlayer = true;
			char.applyPlayerFlip();

			var alivePos = charYep.characterData?.gameplay?.position;
			char.setPosition(charYep.x - (alivePos != null ? alivePos[0] ?? 0 : 0) + char.x, charYep.y - (alivePos != null ? alivePos[1] ?? 0 : 0) + char.y);

			if (PlayState.instance.cameraController != null)
				PlayState.instance.cameraController.followChar(char);

			if (gameOverData != null && gameOverData.gameplay != null && gameOverData.gameplay.death != null) {
				sound = gameOverData.gameplay.death.sound ?? sound;
				music = gameOverData.gameplay.death.music ?? music;
				endSound = gameOverData.gameplay.death.endSound ?? endSound;
			}

			break;
		}

		if (char == null) {
			Console.log("ERROR: Character GameOver not loaded");
			return;
		}
		for (layer in char.layers)
			add(layer);
		add(char);

		PlayState.instance.cameraController.isLock = false;
		PlayState.instance.cameraController.followChar(char);

		FlxG.sound.play(Paths.getPath('gameplay/death/' + sound, 'sound'));

		char.playAnim('firstDeath');

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		if (script.hasScripts)
			script.call("onUpdate", []);
		#end

		if (confirm)
			return;

		if (char != null)
			PlayState.instance?.cameraController?.followChar(char);

		if (char.isFinished('firstDeath')) {
			char.playAnim('deathLoop', true);
			FlxG.sound.playMusic(Paths.getPath('gameplay/death/' + music, 'music'));
		}

		if (Controls.ACCEPT) {
			confirm = true;
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
			confirm = true;
			FlxG.sound.music?.stop();
			close();
			#if HSCRIPT_ALLOWED
			script.call("onBack", []);
			#end
		}

		#if HSCRIPT_ALLOWED
		if (script.hasScripts)
			script.call("postUpdate", []);
		#end
	}

	override public function destroy() {
		if (funkin.play.GameOverSubState.instance?.engine == this)
			funkin.play.GameOverSubState.instance = null;
		super.destroy();
	}
}

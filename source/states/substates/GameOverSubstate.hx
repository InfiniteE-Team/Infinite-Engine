package states.substates;

import game.PlayState;
import flixel.tweens.FlxTween;
import core.json.game.objects.CharacterData;
import game.objects.sprites.Character;

class GameOverSubstate extends MusicBeatSubstate {
	var char:Character = null;
	var gameOverData:CharacterData;

	var sound:String = 'default/fnf_loss_sfx';
	var music:String = 'default/gameOver';
	var endSound:String = 'default/gameOverEnd';

	var songFolder:String;
	var curDifficulty:Int;

	var confirm:Bool = false;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		songFolder = PlayState.instance.songFolder;
		curDifficulty = PlayState.instance.curDifficulty;

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

			gameOverData = modding.vslice.VSliceCharacters.readCharacter(Paths.getPath('data/game/characters/' + data.name, 'json'));

			var deathCharName:String = (gameOverData != null && gameOverData.gameplay != null && gameOverData.gameplay.death != null) ? gameOverData.gameplay.death.character : data.name;

			char = new Character(data.id, deathCharName);
			char.isPlayer = true;
			char.applyPlayerFlip();

			var alivePos = charYep.characterData?.gameplay?.position;
			char.setPosition(charYep.x
				- (alivePos != null ? alivePos[0] ?? 0 : 0)
				+ char.x, charYep.y
				- (alivePos != null ? alivePos[1] ?? 0 : 0)
				+ char.y);

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

		var lossSound = suffixed('gameplay/gameover/fnf_loss_sfx', funkin.play.GameOverSubState.blueBallSuffix, 'sound');
		FlxG.sound.play(lossSound ?? Paths.getPath('game/death/' + sound, 'sound'));

		char.playAnim(deathAnim('firstDeath'));

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

		if (char.isFinished(deathAnim('firstDeath'))) {
			char.playAnim(deathAnim('deathLoop'), true);
			var modMusic = suffixed('gameplay/gameover/gameOver', funkin.play.GameOverSubState.musicSuffix, 'music');
			FlxG.sound.playMusic(modMusic ?? Paths.getPath('game/death/' + music, 'music'));
			if (funkin.play.GameOverSubState.instance != null)
				funkin.play.GameOverSubState.instance.gameOverMusic = FlxG.sound.music;
		}

		if (Controls.ACCEPT && funkin.play.GameOverSubState.instance?.mustNotExit != true) {
			confirm = true;
			char.playAnim(deathAnim('deathConfirm'), true);
			FlxG.sound.music?.stop();
			FlxG.sound.play(Paths.getPath('game/death/' + endSound, 'music'));

			new flixel.util.FlxTimer().start(0.7, function(_) {
				FlxG.camera.fade(flixel.util.FlxColor.BLACK, 2, false, function() {
					close();
					MusicBeatState.switchState(() -> new states.menus.LoadingState(songFolder, curDifficulty));
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

	// V-Slice scripts pick a death variant through these suffixes -JloorDev
	function deathAnim(name:String):String {
		var suffix = funkin.play.GameOverSubState.animationSuffix;
		return suffix != null && suffix != '' && char.existsAnim(name + suffix) ? name + suffix : name;
	}

	// mod sounds aren't bundled assets, funkin.Paths loads them from disk -JloorDev
	static function suffixed(path:String, suffix:String, type:String):Dynamic {
		if (suffix == null || suffix == '')
			return null;
		return type == 'music' ? funkin.Paths.music(path + suffix) : funkin.Paths.sound(path + suffix);
	}

	override public function destroy() {
		if (funkin.play.GameOverSubState.instance?.engine == this)
			funkin.play.GameOverSubState.instance = null;
		super.destroy();
	}
}

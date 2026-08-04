package;

class TitleState extends ScriptState {
	var logo:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;

	var titleText:FunkinSprite;

	var acceptOption:Bool = false;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		MasterAudio.playMenu(Paths.getPath('menus/freakyMenu/freakyMenu', 'music'), 0.6, 102);

		logo = new FlxSprite(-150, -100);
		logo.frames = Paths.getPath('menus/title/logoBumpin', 'animated');
		logo.animation.addByPrefix('bumpin', 'logo bumpin', 24, true);
		logo.antialiasing = SaveData.data.antialiasing;
		logo.animation.play('bumpin', true);
		add(logo);

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getPath('menus/title/gfDanceTitle', 'animated');
		gfDance.animation.addByPrefix('danceLeft', 'gfDance', 24, false, [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]);
		gfDance.animation.addByPrefix('danceRight', 'gfDance', 24, false, [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]);
		gfDance.antialiasing = SaveData.data.antialiasing;
		add(gfDance);

		titleText = new FunkinSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getPath('menus/title/title-screen-text', 'animated');
		titleText.addAnim('idle', 'Idle', 24, true);
		titleText.addAnim('press', 'Confirm', 24, true);
		titleText.antialiasing = SaveData.data.antialiasing;
		titleText.playAnim('idle');
		titleText.updateHitbox();
		add(titleText);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

        if (acceptOption)
			return;

		if (Controls.ACCEPT) {
            acceptOption = true;
            titleText.playAnim('press');
            FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
            FlxG.camera.flash(0xFFFFFFFF, 0.2);
            new FlxTimer().start(1, function(tmr:FlxTimer) {
                ScriptClass.switchState('MainMenuState');
            });
        }
	}

	override public function beatHit(beat:Int) {
		super.beatHit(beat);

		if (beat % 2 == 0) {
			logo.animation.play('bumpin', true);
		}

		danceLeft = !danceLeft;

		if (danceLeft)
            gfDance.animation.play('danceRight', true);
        else
            gfDance.animation.play('danceLeft', true);
	}

	override public function destroy() {
		super.destroy();
		logo.destroy();
		gfDance.destroy();
		titleText.destroy();
		logo = null;
		gfDance = null;
		titleText = null;
	}
}

package game.objects;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class Subtitle extends FlxSpriteGroup {
	var bg:FlxSprite;
	var subs:FlxText;
    var hideTimer:FlxTimer;

	public function new() {
		super();

		bg = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.antialiasing = SaveData.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		subs = new FlxText(0, 200, 670, '');
		subs.setFormat(Paths.getPath('Funkin.otf', 'font'), 30, FlxColor.WHITE, "center");
		subs.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
		subs.antialiasing = SaveData.data.antialiasing;
		subs.scrollFactor.set(0, 0);

		subs.screenCenter(X);
		add(subs);
	}

	public function say(text:String, time:Float) {
		if (text == "") {
			this.visible = false;
			return;
		}
		this.visible = true;

		subs.text = text;

		bg.setGraphicSize(Std.int(subs.width + 20), Std.int(subs.height + 10));
		bg.updateHitbox();

		bg.x = subs.x - 10;
		bg.y = subs.y - 5;

        if (time > 0) {
            hideTimer = new FlxTimer().start(time, function(tmr:FlxTimer) {
                this.visible = false;
                subs.text = "";
            });
        }
	}
}

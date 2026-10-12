package modding.editors.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;

class StatsButton extends Button {
	override public function new(x:Float, y:Float, text:String, ?onClick:Void->Void, ?cam:game.objects.Camera) {
		super(x, y, text, onClick, cam);

		remove(bg, true);
		bg.destroy();
		remove(label, true);
		label.destroy();

		bg = new FlxSprite();
		bg.frames = Paths.getPath('menus/editors/ui/cells', 'animated');
		bg.animation.addByPrefix('idle', 'Cel0', 24, false);
		bg.animation.play('idle');
		bg.scale.set(0.6, 0.6);
		bg.updateHitbox();
		add(bg);

		label = new FlxText(35, 0, bg.width, text);
		label.setFormat(Paths.getPath('Funkin.otf', 'font'), 24, flixel.util.FlxColor.WHITE, 'left');
		label.y = (bg.height / 2) - (label.height / 2);
		add(label);
	}
}

package modding.editors.ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class Tab extends FlxSpriteGroup {
	var bg:FlxSprite;
	var items:Array<flixel.FlxBasic> = [];

	public function new(x:Float, y:Float, type:String) {
		super(x, y);

		bg = new FlxSprite();
		bg.frames = Paths.getPath('menus/editors/ui/tabs', 'animated');
		bg.animation.addByPrefix('idle', type, 24, true);
		bg.animation.play('idle');
		bg.scale.set(0.6, 0.6);
		bg.updateHitbox();
		add(bg);
	}

	public function addItem(item:flixel.FlxBasic, offsetX:Float = 0, offsetY:Float = 0) {
		if (Std.isOfType(item, flixel.FlxObject)) {
			var obj = cast(item, flixel.FlxObject);
			obj.x = x + offsetX;
			obj.y = y + offsetY;
		}
		items.push(item);
	}

	public function getWidth():Float
		return bg.width;

	public function getHeight():Float
		return bg.height;
}

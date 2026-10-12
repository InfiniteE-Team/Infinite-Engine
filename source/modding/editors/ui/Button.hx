package modding.editors.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class Button extends flixel.group.FlxSpriteGroup {
	public var bg:FlxSprite;
	public var label:FlxText;

	var onClickCallback:Void->Void;

	var isHovered:Bool = false;
	var isPressed:Bool = false;

	var cam:game.objects.Camera;

	public function new(x:Float, y:Float, text:String, ?onClick:Void->Void, ?cam:game.objects.Camera) {
		super(x, y);

		this.cam = cam;

		bg = new FlxSprite();
		bg.loadGraphic(Paths.getPath('menus/editors/ui/button', 'image'));
		bg.scale.set(0.7, 0.7);
		bg.updateHitbox();
		add(bg);

		label = new FlxText(0, 0, bg.width, text);
		label.setFormat(Paths.getPath('Funkin.otf', 'font'), 18, FlxColor.WHITE, 'center');
		label.y = (bg.height / 2) - (label.height / 2);
		add(label);

		onClickCallback = onClick;
	}

	public function setText(text:String) {
		label.text = text;
		label.y = (bg.height / 2) - (label.height / 2);
	}

	public function setOnClick(onClick:Void->Void) {
		onClickCallback = onClick;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var mouse = FlxG.mouse.getViewPosition(cam != null ? cam : FlxG.camera);
		var mx = mouse.x;
		var my = mouse.y;
		isHovered = mx >= x && mx <= x + bg.width && my >= y && my <= y + bg.height;

		if (isHovered) {
			if (FlxG.mouse.pressed) {
				bg.color = 0xFF880020;
				if (FlxG.mouse.justPressed && onClickCallback != null)
					onClickCallback();
			} else {
				bg.color = 0xFFBB0030;
			}
		} else {
			bg.color = FlxColor.WHITE;
		}
	}
}

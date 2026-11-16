package modding.editors.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

// the "- [ value ] +" box, shift steps ten times more -JloorDev
class NumberStepper extends flixel.group.FlxSpriteContainer {
	public var value(default, null):Float = 0;

	var minus:FlxSprite;
	var plus:FlxSprite;
	var box:FlxSprite;
	var valueText:FlxText;

	var step:Float;
	var decimals:Int;
	var min:Float;
	var max:Float;
	var cam:flixel.FlxCamera;
	var onChange:Float->Void;

	static final SCALE:Float = 0.6;

	public function new(x:Float, y:Float, value:Float, step:Float = 1, ?cam:flixel.FlxCamera, ?onChange:Float->Void, decimals:Int = 0,
			min:Float = -99999, max:Float = 99999) {
		super(x, y);
		this.step = step;
		this.decimals = decimals;
		this.min = min;
		this.max = max;
		this.cam = cam;
		this.onChange = onChange;

		// positions are relative here, add() moves them to the group -JloorDev
		minus = part('-');
		box = part('content');
		box.x = minus.width;
		plus = part('+');
		plus.x = box.x + box.width;

		valueText = new FlxText(box.x, 0, box.width, '');
		valueText.setFormat(Paths.getPath('Funkin.otf', 'font'), 16, FlxColor.BLACK, 'center');
		valueText.y = (box.height - valueText.height) / 2;

		for (child in [minus, box, plus, valueText])
			add(child);

		setValue(value);
	}

	function part(name:String):FlxSprite {
		var spr = new FlxSprite();
		spr.frames = Paths.getPath('menus/editors/ui/+-count', 'animated');
		spr.animation.addByPrefix('idle', name, 24, false);
		spr.animation.play('idle');
		spr.scale.set(SCALE, SCALE);
		spr.updateHitbox();
		return spr;
	}

	// sets it without calling onChange, for when the selection changes -JloorDev
	public function setValue(v:Float):Void {
		value = Math.max(min, Math.min(max, v));
		valueText.text = Std.string(flixel.math.FlxMath.roundDecimal(value, decimals));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var m = FlxG.mouse.getViewPosition(cam != null ? cam : FlxG.camera);
		var overMinus = minus.overlapsPoint(m, true, cam);
		var overPlus = plus.overlapsPoint(m, true, cam);
		minus.color = overMinus ? 0xFFBB0030 : FlxColor.WHITE;
		plus.color = overPlus ? 0xFFBB0030 : FlxColor.WHITE;

		if (!FlxG.mouse.justPressed || !(overMinus || overPlus))
			return;
		var amount = step * (FlxG.keys.pressed.SHIFT ? 10 : 1);
		setValue(value + (overPlus ? amount : -amount));
		if (onChange != null)
			onChange(value);
	}
}

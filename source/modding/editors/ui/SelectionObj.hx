package modding.editors.ui;

import flixel.FlxSprite;

class SelectionObj extends flixel.group.FlxSpriteGroup {
	var cornerTL:FlxSprite;
	var cornerTR:FlxSprite;
	var cornerBL:FlxSprite;
	var cornerBR:FlxSprite;

	static final SIZE:Int = 62;
	static final THICKNESS:Int = 3;
	static final COLOR:Int = 0xFFCC1144;
	static final PAD:Float = 4;

	public function new() {
		super();

		cornerTL = makeCorner();
		cornerTR = makeCorner();
		cornerBL = makeCorner();
		cornerBR = makeCorner();

		cornerTL.angle = 0;
		cornerTR.angle = 90;
		cornerBL.angle = -90;
		cornerBR.angle = 180;

		add(cornerTL);
		add(cornerTR);
		add(cornerBL);
		add(cornerBR);

		visible = false;
		pulse();
	}

	function makeCorner():FlxSprite {
		var sis = new FlxSprite();
		sis.makeGraphic(SIZE, SIZE, 0x00000000, true);
		sis.pixels.fillRect(new openfl.geom.Rectangle(0, 0, SIZE, THICKNESS), COLOR);
		sis.pixels.fillRect(new openfl.geom.Rectangle(0, 0, THICKNESS, SIZE), COLOR);
		return sis;
	}

	function pulse() {
		for (corner in [cornerTL, cornerTR, cornerBL, cornerBR]) {
			flixel.tweens.FlxTween.tween(corner, {alpha: 0.3}, 0.6, {
				type: flixel.tweens.FlxTween.FlxTweenType.PINGPONG,
				ease: flixel.tweens.FlxEase.sineInOut
			});
		}
	}

	public function trackSprite(sprite:FlxSprite) {
		if (sprite == null) {
			visible = false;
			return;
		}

		visible = true;

		var sx = sprite.x;
		var sy = sprite.y;
		var sw = sprite.width;
		var sh = sprite.height;

		cornerTL.setPosition(sx - PAD, sy - PAD);
		cornerTR.setPosition(sx + sw + PAD - SIZE, sy - PAD);
		cornerBL.setPosition(sx - PAD, sy + sh + PAD - SIZE);
		cornerBR.setPosition(sx + sw + PAD - SIZE, sy + sh + PAD - SIZE);
	}
}

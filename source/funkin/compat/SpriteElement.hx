package funkin.compat;

// flixel-animate's FlxSpriteElement for scripts: puts a sprite inside an atlas frame (gf-qt's speakers) -JloorDev
@:keep
class SpriteElement extends animate.internal.elements.FlxSpriteElement {
	public function new(?sprite:flixel.FlxSprite) {
		super(sprite);
	}
}

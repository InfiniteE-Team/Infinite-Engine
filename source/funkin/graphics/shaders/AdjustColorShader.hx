package funkin.graphics.shaders;

// V-Slice AdjustColorShader for scripts: keeps the values but draws untouched
// shortcut: no color adjustment, port V-Slice's adjustColor.frag when a mod's look depends on it -JloorDev
@:keep
class AdjustColorShader extends flixel.system.FlxAssets.FlxShader {
	public var hue:Float = 0;
	public var saturation:Float = 0;
	public var contrast:Float = 0;
	public var brightness:Float = 0;

	public function new() {
		super();
	}
}

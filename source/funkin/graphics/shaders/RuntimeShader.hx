package funkin.graphics.shaders;

// flixel's FlxRuntimeShader can't be extended from scripts, so they extend this one instead (ftbb's water and sky) -JloorDev
@:scriptable
@:keepSub
@:keep
class RuntimeShader extends flixel.addons.display.FlxRuntimeShader {
	public function new(?fragmentSource:String, ?vertexSource:String) {
		super(fragmentSource, vertexSource);
	}
}

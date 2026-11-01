package core.render.shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.display.BitmapData;
import openfl.display.BlendMode;

class CustomBlendShader extends FlxRuntimeShader {
	public var sourceSwag(default, set):BitmapData;
	public var backgroundSwag(default, set):BitmapData;
	public var blendSwag(default, set):Int;

	function set_sourceSwag(v:BitmapData):BitmapData {
		data.sourceSwag.input = v;
		return sourceSwag = v;
	}

	function set_backgroundSwag(v:BitmapData):BitmapData {
		data.backgroundSwag.input = v;
		return backgroundSwag = v;
	}

	function set_blendSwag(v:Int):Int {
		data.blendMode.value = [v];
		return blendSwag = v;
	}

	public function new() {
		super(openfl.utils.Assets.getText('assets/shaders/customBlend.frag'));
	}
}

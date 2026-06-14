package game.graphics.shaders.hardcode;

import flixel.addons.display.FlxRuntimeShader;
import core.json.objects.NoteSkinData;

class RGBShader {
	static var _src:String = null;

	static function getSrc():String {
		if (_src == null) {
			var path = Paths.getPath('noteRGB', 'shaders');
			if (sys.FileSystem.exists(path)) {
				_src = sys.io.File.getContent(path);
			} else {
				Trace.traceOnce('Shader not found: $path', true);
			}
		}
		return _src;
	}

	public static function applyByAnimation(sprite:flixel.FlxSprite, noteSkinData:NoteSkinData, animationName:String) {
		if (sprite == null || noteSkinData == null || animationName == null)
			return;

		if (noteSkinData.colorPalette == null)
			return;

		var colors:Array<String> = Reflect.field(noteSkinData.colorPalette, animationName);
		if (colors == null || colors.length < 3)
			return;

		applyRGB(sprite, colors[0], colors[1], colors[2]);
	}

	public static function applyRGB(sprite:flixel.FlxSprite, hexR:String, hexG:String, hexB:String) {
		if (sprite == null)
			return;

		var src = getSrc();
		if (src == null)
			return;

		var shader:FlxRuntimeShader;
		if (sprite.shader != null && (sprite.shader is FlxRuntimeShader))
			shader = cast sprite.shader;
		else {
			shader = new FlxRuntimeShader(src);
			sprite.shader = shader;
		}

		shader.setFloatArray('r', hexToVec(hexR));
		shader.setFloatArray('g', hexToVec(hexG));
		shader.setFloatArray('b', hexToVec(hexB));
		shader.setFloat('mult', 1.0);
		sprite.shader = shader;
	}

	static function hexToVec(hex:String):Array<Float> {
		var clean = hex.toUpperCase();
		if (clean.startsWith('0X'))
			clean = clean.substr(2);
		if (clean.length == 8)
			clean = clean.substr(2);
		var val = Std.parseInt('0x' + clean);
		return [((val >> 16) & 0xFF) / 255.0, ((val >> 8) & 0xFF) / 255.0, (val & 0xFF) / 255.0];
	}

	@:noCompletion
	private static function extractNoteIndex(animationName:String):Int {
		if (animationName == null)
			return -1;

		var regex = ~/note(\d)/;
		if (regex.match(animationName)) {
			return Std.parseInt(regex.matched(1));
		}
		return -1;
	}
}

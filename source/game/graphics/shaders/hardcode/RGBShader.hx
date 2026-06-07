package game.graphics.shaders.hardcode;

import flixel.addons.display.FlxRuntimeShader;
import core.json.objects.NoteSkinData;

class RGBShader {
	static var _src:String = null;

	static function getSrc():String {
		if (_src == null) {
			var path = Paths.getPath('colorNotes', 'shaders');
			if (sys.FileSystem.exists(path)) {
				_src = sys.io.File.getContent(path);
			} else {
				Trace.traceOnce('Shader not found: $path', true);
			}
		}
		return _src;
	}

	public static function applyHexColor(sprite:flixel.FlxSprite, hexColor:Int) {
		if (sprite == null)
			return;

		var src = getSrc();
		if (src == null)
			return;

		var r = ((hexColor >> 16) & 0xFF) / 255.0;
		var g = ((hexColor >> 8) & 0xFF) / 255.0;
		var b = (hexColor & 0xFF) / 255.0;

		var shader:FlxRuntimeShader;
		if (sprite.shader != null && (sprite.shader is FlxRuntimeShader))
			shader = cast sprite.shader;
		else {
			shader = new FlxRuntimeShader(src);
			sprite.shader = shader;
		}
		shader.setFloatArray('noteColor', [r, g, b, 1.0]);
		sprite.shader = shader;
	}

	public static function applyHexString(sprite:flixel.FlxSprite, hexString:String) {
		if (sprite == null || hexString == null)
			return;

		try {
			var hexValue = Std.parseInt(hexString);
			applyHexColor(sprite, hexValue);
		} catch (e:Dynamic) {
			Trace.traceOnce('Error parsing hex: $hexString - $e', true);
		}
	}

	public static function applyByAnimation(sprite:flixel.FlxSprite, noteSkinData:NoteSkinData, animationName:String) {
		if (sprite == null || noteSkinData == null || animationName == null)
			return;

		if (noteSkinData.colorPalette == null)
			return;

		var hexString:String = Reflect.field(noteSkinData.colorPalette, animationName);
		if (hexString == null)
			return;

		applyHexString(sprite, hexString);
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

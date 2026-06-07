package game.graphics.shaders;

import game.objects.Camera;
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;

class CustomShader {
	public static function loadShader(name:String):FlxRuntimeShader {
		var shaderPath = Paths.getPath('$name', 'shaders');
		if (!sys.FileSystem.exists(shaderPath)) {
			Trace.traceOnce('[CustomShader] Shader not found: $name', true);
			return null;
		}
		return new FlxRuntimeShader(sys.io.File.getContent(shaderPath));
	}

	public static function applyToCamera(name:String, cam:Camera) {
		var sh = loadShader(name);
		if (sh == null)
			return;

		var filter = new ShaderFilter(sh);
		if (cam.filters == null)
			cam.filters = [filter];
		else
			cam.filters.push(filter);
	}
}

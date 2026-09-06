package game.graphics.shaders;

import game.objects.Camera;
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;

class CustomShader {
	static var appliedFilters:Map<Camera, Array<ShaderFilter>> = new Map();

	public static function loadShader(name:String):FlxRuntimeShader {
		var shaderPath = Paths.getPath('$name', 'shaders');
		if (!sys.FileSystem.exists(shaderPath)) {
			Trace.traceOnce('[CustomShader] Shader not found: $name', true);
			return null;
		}
		return new FlxRuntimeShader(sys.io.File.getContent(shaderPath));
	}

	public static function applyToCamera(name:String, cam:Camera):FlxRuntimeShader {
		var sh = loadShader(name);
		if (sh == null)
			return null;

		var filter = new ShaderFilter(sh);
		if (cam.filters == null)
			cam.filters = [filter];
		else
			cam.filters.push(filter);

		if (!appliedFilters.exists(cam))
			appliedFilters.set(cam, []);
		appliedFilters.get(cam).push(filter);

		return sh;
	}

	public static function removeFromCamera(sh:FlxRuntimeShader, cam:Camera):Void {
		if (cam.filters == null)
			return;
		cam.filters = cam.filters.filter(f -> {
			var sf = Std.downcast(f, ShaderFilter);
			return sf == null || sf.shader != sh;
		});
		cam.pruneEmptyFilters();
	}

	public static function clearAll():Void {
		for (cam in appliedFilters.keys()) {
			if (!appliedFilters.exists(cam))
				return;
			var filters = appliedFilters.get(cam);
			if (cam.filters != null) {
				cam.filters = cam.filters.filter(f -> {
					var sf = Std.downcast(f, ShaderFilter);
					return sf == null || !filters.contains(sf);
				});
				cam.pruneEmptyFilters();
			}
			appliedFilters.remove(cam);
		}
		appliedFilters.clear();
	}
}

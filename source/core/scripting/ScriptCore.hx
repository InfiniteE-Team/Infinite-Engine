package core.scripting;

import states.MusicBeatState;
import rulescript.RuleScript;

class ScriptCore {
	public static var sharedContext:rulescript.Context = new rulescript.Context();

	var scripts:Array<RuleScript> = [];
	var paths:Array<String> = [];
	var modifiedTimes:Array<Float> = [];
	var state:MusicBeatState;

	public function new(state:MusicBeatState) {
		this.state = state;
	}

	public function load(path:String) {
		if (path == null || !sys.FileSystem.exists(path))
			return;

		var script = new RuleScript(null, null, sharedContext);
		script.errorHandler = (e) -> Trace.traceOnce('[Script] $path → ${e.message}');
		script.superInstance = state;
		script.access.setVariable("add", state.add);
		script.access.setVariable("remove", state.remove);
		script.tryExecute(sys.io.File.getContent(path));
		scripts.push(script);
		paths.push(path);
		modifiedTimes.push(sys.FileSystem.stat(path).mtime.getTime());
	}

	public function exposeStatics(cls:Class<Dynamic>) {
		for (field in Type.getClassFields(cls)) {
			var value = Reflect.getProperty(cls, field);
			for (script in scripts)
				script.access.setVariable(field, value);
		}
	}

	public function call(name:String, args:Array<Dynamic>):Dynamic {
		var result:Dynamic = null;
		for (script in scripts)
			result = script.access.callFunction(name, args);
		return result;
	}

	public function hotReload() {
		for (i in 0...paths.length) {
			if (!sys.FileSystem.exists(paths[i]))
				continue;
			var modified = sys.FileSystem.stat(paths[i]).mtime.getTime();
			if (modified > modifiedTimes[i])
				reload(i);
		}
	}

	function reload(i:Int) {
		scripts[i].access.resetInterp();
		scripts[i].superInstance = state;
		scripts[i].access.setVariable("add", state.add);
		scripts[i].access.setVariable("remove", state.remove);
		scripts[i].tryExecute(sys.io.File.getContent(paths[i]));
		modifiedTimes[i] = sys.FileSystem.stat(paths[i]).mtime.getTime();
		scripts[i].access.callFunction("postCreate", []);
		Trace.traceOnce('Reload ${paths[i]}');
	}

	public function destroy()
	{
		scripts = null;
		paths = null;
		modifiedTimes = null;
		state = null;
	}
}
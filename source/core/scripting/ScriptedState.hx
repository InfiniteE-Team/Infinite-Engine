package core.scripting;

import rulescript.RuleScript;
import states.MusicBeatState;

class ScriptedState {
	// example load: ScriptedState.load('customClass');
	// customClass.hx or .hxc in assets/states/
	public static function go(className:String, ?args:Array<Dynamic>):Void {
		MusicBeatState.switchState(load(className, args));
	}

	public static function load(className:String, ?args:Array<Dynamic>):MusicBeatState {
		var path = Paths.getPath(className, 'states');
		if (path == null || !sys.FileSystem.exists(path)) {
			Trace.traceOnce('ScriptedState: Not found states/$className.hx');
			return null;
		}

		var ctx = ScriptHandler.globalContext;

		var script = new RuleScript(null, null, ctx);
		script.errorHandler = (e) -> Trace.traceOnce('ScriptedState: $className → ${e.message}');
		script.tryExecute(sys.io.File.getContent(path));

		var access = RuleScript.resolveScriptedClass(className, ctx);
		if (access == null) {
			Trace.traceOnce('ScriptedState: Class "$className" not found $path');
			return null;
		}

		return cast access.createInstance(args ?? []);
	}
}

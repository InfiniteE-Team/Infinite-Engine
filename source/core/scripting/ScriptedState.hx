package core.scripting;

import rulescript.RuleScript;
import states.MusicBeatState;
import states.substates.MusicBeatSubstate;

class ScriptedState {
	// example load: ScriptedState.load('customClass');
	// customClass.hx or .hxc in assets/states/
	public static function switchState(className:String, ?args:Array<Dynamic>):Void {
		MusicBeatState.switchState(load(className, args));
	}

	public static function openSubstate(className:String, ?args:Array<Dynamic>):Void {
		MusicBeatSubstate.openSubstate(loadSub(className, args));
	}

	public static function load(className:String, ?args:Array<Dynamic>):MusicBeatState {
		var path = Paths.getPath(className, 'states');

		if (path == null || !sys.FileSystem.exists(path)) {
			Trace.traceOnce('ScriptedState: Not found source/states/$className.hx', true);
			return null;
		}

		var ctx = ScriptHandler.globalContext;

		var script = new RuleScript(null, null, ctx);
		script.errorHandler = (e) -> Trace.traceOnce('ScriptedState: $className → ${e.message}', true);
		script.tryExecute(sys.io.File.getContent(path));

		var access = RuleScript.resolveScriptedClass(className, ctx);
		if (access == null) {
			Trace.traceOnce('ScriptedState: Class "$className" not found $path', true);
			return null;
		}

		return cast access.createInstance(args ?? []);
	}

	public static function loadSub(className:String, ?args:Array<Dynamic>):MusicBeatSubstate {
		var path = Paths.getPath(className, 'substates');

		if (path == null || !sys.FileSystem.exists(path)) {
			Trace.traceOnce('ScriptedState: Not found source/substates/$className.hx', true);
			return null;
		}

		var ctx = ScriptHandler.globalContext;

		var script = new RuleScript(null, null, ctx);
		script.errorHandler = (e) -> Trace.traceOnce('ScriptedState: $className → ${e.message}', true);
		script.tryExecute(sys.io.File.getContent(path));

		var access = RuleScript.resolveScriptedClass(className, ctx);
		if (access == null) {
			Trace.traceOnce('ScriptedState: Class "$className" not found $path', true);
			return null;
		}

		return cast access.createInstance(args ?? []);
	}
}

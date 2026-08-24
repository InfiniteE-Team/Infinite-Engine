package modding.scripting.types;

import hxscript.Module;
import hxscript.Environment;
import modding.scripting.ScriptHandler;

class ScriptClass {
	public static function switchState(className:String, ?args:Array<Dynamic>):Void {
		MusicBeatState.switchState(() -> load(className, args));
	}

	public static function load(className:String, ?args:Array<Dynamic>):MusicBeatState {
		var path = Paths.getPath(className, 'states');

		if (path == null || !sys.FileSystem.exists(path)) {
			Trace.traceOnce('ScriptClass: Not found source/states/$className.hx', true);
			return null;
		}

		var content = sys.io.File.getContent(path);

		if (checkIsClass(content)) {
			return loadAsClass(path, className, content, args);
		} else {
			var state = new MusicBeatState();
			var handler = new ScriptHandler(state);
			handler.load(path);
			handler.executeAll();
			@:privateAccess
			state.script = handler;
			return state;
		}
	}

	public static function loadSub(className:String, ?args:Array<Dynamic>):states.substates.MusicBeatSubstate {
		var path = Paths.getPath(className, 'substates');

		if (path == null || !sys.FileSystem.exists(path)) {
			Trace.traceOnce('ScriptClass: Not found source/substates/$className.hx', true);
			return null;
		}

		var content = sys.io.File.getContent(path);

		if (checkIsClass(content)) {
			return loadAsClass(path, className, content, args);
		} else {
			var substate = new states.substates.MusicBeatSubstate();
			var handler = new ScriptHandler(substate);
			handler.load(path);
			handler.executeAll();
			@:privateAccess
			substate.script = handler;
			return substate;
		}
	}

	public static function openSubstate(className:String, ?args:Array<Dynamic>):Void {
		var sub = loadSub(className, args);
		if (sub != null)
			FlxG.state.openSubState(sub);
	}

	public static function loadAsClass<T>(path:String, className:String, content:String, args:Array<Dynamic>):T {
		var env = new hxscript.Environment();

		for (k => v in ScriptHandler.globalEnv.variables)
			env.variables.set(k, v);

		var module:Module;
		try {
			module = new Module(content, className, [], path);
		} catch (e) {
			Trace.traceOnce('ScriptClass: parse error $className → ${e.message}', true);
			return null;
		}

		env.addModule(module);
		env.start();

		var type = env.resolve(className);
		if (type == null) {
			Trace.traceOnce('ScriptClass: Class "$className" not found in $path', true);
			return null;
		}

		if (!(type is hxscript.types.ScriptedClass)) {
			Trace.traceOnce('ScriptClass: "$className" is not a class', true);
			return null;
		}

		var cls:hxscript.types.ScriptedClass = cast type;
		var instance:T = cast cls.typeCreateInstance(args ?? []);

		return instance;
	}

	private static function checkIsClass(content:String):Bool {
		var cleanContent = ~/(\/\/[^\n]*|\/\*[\s\S]*?\*\/)/g.replace(content, "");
		var classRegex = ~/\b(public|private|final|extern)?\s*class\s+[a-zA-Z_]\w*\b/;
		return classRegex.match(cleanContent) || ~/\b(extends|implements)\b/.match(cleanContent);
	}
}

package modding.scripting.types;

import hxscript.Module;
import hxscript.Environment;
import modding.scripting.ScriptHandler;

class ScriptClass {
	public static function switchState(className:String, ?args:Array<Dynamic>):Void {
		var state = load(className, args);
		if (state == null)
			return;
		MusicBeatState.switchState(() -> state);
	}

	public static function load(className:String, ?args:Array<Dynamic>):MusicBeatState {
		var path = Paths.getPath(className, 'states');

		if (path == null || !sys.FileSystem.exists(path)) {
			Console.log('ScriptClass: Not found source/states/$className.hx', true);
			return loadStateFallback(className, args);
		}

		var content = sys.io.File.getContent(path);

		if (checkIsClass(content)) {
			var state = loadAsClass(path, className, content, args);
			if (state != null)
				return state;
			// El script del mod falló — intentar fallback
			return loadStateFallback(className, args);
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

	static function loadStateFallback(className:String, ?args:Array<Dynamic>):MusicBeatState {
		var basePath = '${core.assets.Library.baseFolder}/source/states/$className.hx';
		if (sys.FileSystem.exists(basePath)) {
			Console.log('ScriptClass: Fallback > base engine $className', true);
			var content = sys.io.File.getContent(basePath);
			if (checkIsClass(content)) {
				var state:MusicBeatState = loadAsClass(basePath, className, content, args);
				if (state != null)
					return state;
			}
		}

		var nativeCls = Type.resolveClass('states.$className');
		if (nativeCls != null) {
			Console.log('ScriptClass: Fallback > native class states.$className', true);
			return cast Type.createInstance(nativeCls, args ?? []);
		}

		Console.log('ScriptClass: No fallback found for $className', true);
		return null;
	}

	public static function loadSub(className:String, ?args:Array<Dynamic>):states.substates.MusicBeatSubstate {
		var path = Paths.getPath(className, 'substates');

		if (path == null || !sys.FileSystem.exists(path)) {
			Console.log('ScriptClass: Not found source/substates/$className.hx', true);
			return loadSubFallback(className, args);
		}

		var content = sys.io.File.getContent(path);

		if (checkIsClass(content)) {
			var sub = loadAsClass(path, className, content, args);
			if (sub != null)
				return sub;
			return loadSubFallback(className, args);
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

	static function loadSubFallback(className:String, ?args:Array<Dynamic>):states.substates.MusicBeatSubstate {
		var basePath = '${core.assets.Library.baseFolder}/source/substates/$className.hx';
		if (sys.FileSystem.exists(basePath)) {
			Console.log('ScriptClass: Fallback > base engine substate $className', true);
			var content = sys.io.File.getContent(basePath);
			if (checkIsClass(content)) {
				var sub:states.substates.MusicBeatSubstate = loadAsClass(basePath, className, content, args);
				if (sub != null)
					return sub;
			}
		}

		var nativeCls = Type.resolveClass('states.substates.$className');
		if (nativeCls != null) {
			Console.log('ScriptClass: Fallback > native substate states.substates.$className', true);
			return cast Type.createInstance(nativeCls, args ?? []);
		}

		Console.log('ScriptClass: No fallback found for substate $className', true);
		return null;
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
			Console.log('ScriptClass: parse error $className > ${e.message}', true);
			return null;
		}

		env.addModule(module);
		for (path => mod in ScriptHandler.moduleRegistry) {
			env.addModule(mod);
		}

		try {
			env.start();
		} catch (e) {
			Console.log('ScriptClass: runtime error starting $className > ${e.message}', true);
			return null;
		}

		var type = env.resolve(className);
		if (type == null) {
			Console.log('ScriptClass: Class "$className" not found in $path', true);
			return null;
		}

		if (!(type is hxscript.types.ScriptedClass)) {
			Console.log('ScriptClass: "$className" is not a class', true);
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

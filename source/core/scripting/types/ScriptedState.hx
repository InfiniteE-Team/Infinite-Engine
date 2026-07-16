package core.scripting.types;

import rulescript.RuleScript;
import states.substates.MusicBeatSubstate;
import core.scripting.ScriptHandler;

class ScriptedState {
	// example load: ScriptedState.load('customClass');
	// customClass.hx or .hxc in assets/source/states/
	public static function switchState(className:String, ?args:Array<Dynamic>):Void {
		MusicBeatState.switchState(() -> load(className, args));
	}

	public static function load(className:String, ?args:Array<Dynamic>):MusicBeatState {
		var path = Paths.getPath(className, 'states');

		if (path == null || !sys.FileSystem.exists(path)) {
			Trace.traceOnce('ScriptedState: Not found source/states/$className.hx', true);
			return null;
		}

		var ctx = ScriptHandler.globalContext;

		var content = sys.io.File.getContent(path);
		var parser = new rulescript.parsers.HxParser();
		parser.allowAll();

		var moduleDecls:Array<hscript.Expr.ModuleDecl>;
		try {
			moduleDecls = parser.parseModule(content);
		} catch (e) {
			Trace.traceOnce('ScriptedState: parse error $className → ${e.details()}', true);
			return null;
		}

		var module = new rulescript.types.ScriptedModule(className, moduleDecls, ctx);

		for (name => type in module.types) {
			ctx.types.set(name, cast type);
			rulescript.scriptedClass.RuleScriptedClassUtil.registerRuleScriptedClass(name, cast type);
		}

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
		var content = sys.io.File.getContent(path);
		var parser = new rulescript.parsers.HxParser();
		parser.allowAll();

		var moduleDecls:Array<hscript.Expr.ModuleDecl>;
		try {
			moduleDecls = parser.parseModule(content);
		} catch (e) {
			Trace.traceOnce('ScriptedState: parse error $className → ${e.details()}', true);
			return null;
		}

		var module = new rulescript.types.ScriptedModule(className, moduleDecls, ctx);

		for (name => type in module.types) {
			ctx.types.set(name, cast type);
			rulescript.scriptedClass.RuleScriptedClassUtil.registerRuleScriptedClass(name, cast type);
		}

		var access = RuleScript.resolveScriptedClass(className, ctx);
		if (access == null) {
			Trace.traceOnce('ScriptedState: Class "$className" not found $path', true);
			return null;
		}

		return cast access.createInstance(args ?? []);
	}
}

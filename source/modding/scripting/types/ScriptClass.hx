package modding.scripting.types;

import rulescript.RuleScript;
import states.substates.MusicBeatSubstate;
import modding.scripting.ScriptHandler;

class ScriptClass {
	// example load: ScriptClass.load('customClass');
	// customClass.hx or .hxc in assets/source/states/
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

	public static function loadSub(className:String, ?args:Array<Dynamic>):MusicBeatSubstate {
        var path = Paths.getPath(className, 'substates');

        if (path == null || !sys.FileSystem.exists(path)) {
            Trace.traceOnce('ScriptClass: Not found source/substates/$className.hx', true);
            return null;
        }

        var content = sys.io.File.getContent(path);

        if (checkIsClass(content)) {
            return loadAsClass(path, className, content, args);
        } else {
            var substate = new MusicBeatSubstate();
            var handler = new ScriptHandler(substate);
            handler.load(path);
            handler.executeAll();
            @:privateAccess
            substate.script = handler;
            return substate;
        }
    }

	public static function openSubstate(className:String, ?args:Array<Dynamic>):Void {
		var subStateInstance = loadSub(className, args);
		if (subStateInstance != null) {
			FlxG.state.openSubState(subStateInstance);
		}
	}

	public static function loadAsClass<T>(path:String, className:String, content:String, args:Array<Dynamic>):T {
        var ctx = ScriptHandler.globalContext;

        var parser = new rulescript.parsers.HxParser();
        parser.allowAll();

        var moduleDecls:Array<hscript.Expr.ModuleDecl>;
        try {
            moduleDecls = parser.parseModule(content);
        } catch (e) {
            Trace.traceOnce('ScriptClass: parse error $className → ${e.details()}', true);
            return null;
        }

        var module = new rulescript.types.ScriptedModule(className, moduleDecls, ctx);

        for (name => type in module.types) {
            ctx.types.set(name, cast type);
            rulescript.scriptedClass.RuleScriptedClassUtil.registerRuleScriptedClass(name, cast type);
        }

        var access = RuleScript.resolveScriptedClass(className, ctx);
        if (access == null) {
            Trace.traceOnce('ScriptClass: Class "$className" not found $path', true);
            return null;
        }

        return cast access.createInstance(args ?? []);
    }

    private static function checkIsClass(content:String):Bool {
        var cleanContent = ~/(\/\/[^\n]*|\/\*[\s\S]*?\*\/)/g.replace(content, "");
        var classRegex = ~/\b(public|private|final|extern)?\s*class\s+[a-zA-Z_]\w*\b/;
        return classRegex.match(cleanContent) || ~/\b(extends|implements)\b/.match(cleanContent);
    }
}

package core.scripting;

import rulescript.types.ScriptedTypeUtil;
import rulescript.scriptedClass.RuleScriptedClassUtil;

class ScriptResolver {

    static var initialized:Bool = false;
    public static var searchPaths:Array<{prefix:String, type:String}> = [
		{prefix: 'classes/', type: 'script'}, // scripts/classes/Name.hx  <- put shared classes here
		{prefix: '', type: 'script'}, // scripts/Name.hx (next to hud.hx, character scripts, etc.)
		{prefix: '', type: 'states'}, // source/states/Name.hx
		{prefix: '', type: 'substates'}, // source/substates/Name.hx
	];

    public static function init() {
        if (initialized)
            return;
        initialized = true;

        ScriptedTypeUtil.resolveModule = resolveModule;

        final baseResolve = ScriptedTypeUtil.resolveScript;
        ScriptedTypeUtil.resolveScript = function(name:String):Dynamic {
			var result = baseResolve(name);
			if (result != null)
				RuleScriptedClassUtil.registerRuleScriptedClass(name, cast result);
			return result;
		};
    }

    public static function resolveModule(name:String):Array<hscript.Expr.ModuleDecl> {
		if (name == null || name == '')
			return null;

		var path = findScriptFile(name);
		if (path == null)
			return null;

		var parser = new rulescript.parsers.HxParser();
		parser.allowAll();

		try {
			return parser.parseModule(sys.io.File.getContent(path));
		} catch (e) {
			Trace.traceOnce('ScriptResolver: parse error resolving "$name" ($path) -> ${e.details()}', true);
			return null;
		}
	}

    static function findScriptFile(modulePath:String):String {
		var relPath = modulePath.split('.').join('/');

		for (entry in searchPaths) {
			var path:String = Paths.getPath(entry.prefix + relPath, entry.type);
			if (path != null && sys.FileSystem.exists(path) && haxe.io.Path.extension(path) != 'lua')
				return path;
		}

		return null;
	}
}
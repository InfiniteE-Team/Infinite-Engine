package core.scripting.types;

import rulescript.parsers.HxParser;
import rulescript.types.ScriptedTypedef;

class ScriptedTypeDef extends ScriptedTypedef {
	public static function loadTypedef(typeDefName:String, ?args:Array<Dynamic>):ScriptedTypeDef {
		var path = Paths.getPath(typeDefName, 'typedefs');

		if (path == null || !sys.FileSystem.exists(path)) {
			Trace.traceOnce('ScriptedState: Not found source/typedefs/$typeDefName.hx', true);
			return null;
		}

		var parser = new HxParser();
        parser.allowAll();
		var content = sys.io.File.getContent(path);

		try {
            var ast = parser.parser.parseString(content);
            var typedefObj = new ScriptedTypeDef(ast);
            return typedefObj;
        } catch (e:Dynamic) {
            Trace.traceOnce('Error to parse typedef $typeDefName: $e', true);
            return null;
        }
	}
}

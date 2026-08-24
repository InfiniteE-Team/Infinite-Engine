package modding.scripting.types;

import hxscript.Module;
import hxscript.types.ScriptedTypedef;

class ScriptedTypeDef {
    public static function loadTypedef(typeDefName:String):ScriptedTypedef {
        var path = Paths.getPath(typeDefName, 'typedefs');

        if (path == null || !sys.FileSystem.exists(path)) {
            Trace.traceOnce('ScriptedTypeDef: Not found source/typedefs/$typeDefName.hx', true);
            return null;
        }
        var content = sys.io.File.getContent(path);

        try {
            var module = new Module(content, typeDefName, [], path);
            var type = module.types.get(typeDefName);
            if (type is ScriptedTypedef)
                return cast type;
            Trace.traceOnce('ScriptedTypeDef: "$typeDefName" is not a typedef', true);
            return null;
        } catch (e) {
            Trace.traceOnce('ScriptedTypeDef: Error parsing $typeDefName: ${e.message}', true);
            return null;
        }
    }
}
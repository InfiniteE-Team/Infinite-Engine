package modding.scripting;

import rulescript.RuleScript;
import rulescript.parsers.HxParser;

class ScriptHandler {
	public static var globalContext:rulescript.Context = new rulescript.Context();

	var scripts:Array<RuleScript> = [];
	var typedefs:Map<String, modding.scripting.types.ScriptedTypeDef> = [];

	var luaScripts:Array<modding.scripting.lua.LuaScript> = [];

	var paths:Array<String> = [];
	var modifiedTimes:Array<Float> = [];
	var pendingPaths:Array<String> = [];

	// this in scripts.
	var superInstance:Dynamic;

	var extraVars:Map<String, Dynamic> = [];

	public function new(superInstance:Dynamic) {
		this.superInstance = superInstance;
	}

	public function expose(name:String, value:Dynamic):Void {
		extraVars.set(name, value);
		setVar(name, value);
		for (script in luaScripts)
			script.expose(name, value);
	}

	public function load(path:String):Void {
		if (path == null || !sys.FileSystem.exists(path))
			return;

		if (haxe.io.Path.extension(path) == 'lua') {
			var script = new modding.scripting.lua.LuaScript(path, superInstance);
			luaScripts.push(script);
			for (name => value in extraVars)
				script.expose(name, value);
			return;
		}
		pendingPaths.push(path);
		Trace.traceOnce('[ScriptHandler] find: $path');
	}

	public function loadFolder(folder:String):Void {
		var resolved = core.assets.Library.findLib(folder);
		if (resolved == null || !sys.FileSystem.exists(resolved))
			return;
		for (file in sys.FileSystem.readDirectory(resolved)) {
			if (file.endsWith('.hx') || file.endsWith('.lua') || file.endsWith('.hxc'))
				load('$resolved/$file');
		}
	}

	public function loadTypedef(name:String):Void {
		var td = modding.scripting.types.ScriptedTypeDef.loadTypedef(name);
		if (td != null) {
			typedefs.set(name, td);
			for (script in scripts) {
				var data = td.resolve(script.access.execute);
				if (data != null) {
					script.access.setVariable(name, data);
				} else {
					Trace.traceOnce("Error typedef not find the content ideal");
				}
			}
		}
	}

	public function executeAll():Void {
		for (path in pendingPaths) {
			var script = buildScript(path);
			if (script == null)
				continue;
			scripts.push(script);
			paths.push(path);
			modifiedTimes.push(sys.FileSystem.stat(path).mtime.getTime());
		}
		pendingPaths = [];
	}

	public function call(name:String, args:Array<Dynamic>):Dynamic {
		if (scripts == null)
			return null;
		if (name == "postCreate") {
			for (script in luaScripts)
				script.registersuperInstance();
		}
		var result:Dynamic = null;
		for (script in scripts) {
			if (script.interp.access.variableExists(name))
				result = script.access.callFunction(name, args);
		}
		for (script in luaScripts)
			result = script.call(name, args);
		return result;
	}

	public function callCancellable(name:String, args:Array<Dynamic>):Bool {
		if (scripts == null)
			return false;
		for (script in scripts) {
			var result = script.access.callFunction(name, args);
			if (result == true)
				return true;
		}
		for (script in luaScripts) {
			if (script.callCancellable(name, args))
				return true;
		}
		return false;
	}

	public function exposeStatics(cls:Class<Dynamic>):Void {
		for (field in Type.getClassFields(cls)) {
			var value = Reflect.getProperty(cls, field);
			setVar(field, value);
		}
	}

	public function hotReload():Void {
		if (paths == null)
			return;
		for (i in 0...paths.length) {
			if (!sys.FileSystem.exists(paths[i]))
				continue;
			var mtime = sys.FileSystem.stat(paths[i]).mtime.getTime();
			if (mtime > modifiedTimes[i])
				reload(i);
		}
	}

	function buildScript(path:String):Null<RuleScript> {
		var parser = new HxParser();
		parser.allowAll();
		var script = new RuleScript(null, parser, globalContext);
		setupScript(script);
		script.errorHandler = (error:haxe.Exception) -> {
			var pos = script.interp.access.posInfos();
			var file = pos.fileName;
			var line = pos.lineNumber;
			var msg = switch (Std.string(error.message)) {
				case s if (s.startsWith("EUnknownVariable(")):
					'Unknown variable: ${s.substring(17, s.length - 1)}';
				case s if (s.startsWith("EInvalidAccess(")):
					'Invalid field access: ${s.substring(15, s.length - 1)}';
				case s: s;
			};
			Trace.traceOnce('[$file:$line] Script error: $msg');
		};

		try {
			var parsed = parser.parse(sys.io.File.getContent(path));
			script.execute(parsed);
		} catch (e:hscript.Expr.Error) {
			#if hscriptPos
			Trace.traceOnce('[${haxe.io.Path.withoutDirectory(path)}:${e.line}] Parse/runtime error: ${hscript.Printer.errorToString(e)}');
			#else
			Trace.traceOnce('[${haxe.io.Path.withoutDirectory(path)}] Error: ${e}');
			#end
		} catch (e) {
			Trace.traceOnce('[${haxe.io.Path.withoutDirectory(path)}] Unexpected: ${e.details()}');
		}
		return script;
	}

	function setupScript(script:RuleScript):Void {
		script.superInstance = superInstance;

		for (name => value in extraVars)
			script.access.setVariable(name, value);

		for (name => td in typedefs) {
			var data = td.resolve(script.access.execute);
			if (data != null) {
				script.access.setVariable(name, data);
			}
		}
	}

	function setVar(name:String, value:Dynamic):Void {
		for (script in scripts)
			script.access.setVariable(name, value);
	}

	function reload(i:Int):Void {
		scripts[i].access.resetInterp();
		setupScript(scripts[i]);
		scripts[i].tryExecute(sys.io.File.getContent(paths[i]));
		modifiedTimes[i] = sys.FileSystem.stat(paths[i]).mtime.getTime();
		scripts[i].access.callFunction('postCreate', []);
		Trace.traceOnce('[ScriptHandler] hot-reloaded: ${paths[i]}');
	}

	public function destroy():Void {
		scripts = null;
		paths = null;
		modifiedTimes = null;
		extraVars = null;
		superInstance = null;
		for (script in luaScripts)
			script.destroy();
		pendingPaths = null;
		typedefs = null;
		luaScripts = null;
	}
}

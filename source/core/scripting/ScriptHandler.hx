package core.scripting;

import rulescript.RuleScript;
import rulescript.parsers.HxParser;

class ScriptHandler {
	public static var globalContext:rulescript.Context = new rulescript.Context();

	var scripts:Array<RuleScript> = [];
	var luaScripts:Array<core.scripting.lua.LuaScript> = [];

	var paths:Array<String> = [];
	var modifiedTimes:Array<Float> = [];
	var pendingPaths:Array<String> = [];

	// this in scripts.
	var owner:Dynamic;

	var extraVars:Map<String, Dynamic> = [];

	public function new(owner:Dynamic) {
		this.owner = owner;
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
			var script = new core.scripting.lua.LuaScript(path, owner);
			luaScripts.push(script);
			for (name => value in extraVars)
				script.expose(name, value);
			return;
		}
		pendingPaths.push(path);
		Trace.traceOnce('[ScriptHandler] enqueued: $path');
	}

	public function loadFolder(folder:String):Void {
		var resolved = Paths.findLib(folder);
		if (resolved == null || !sys.FileSystem.exists(resolved))
			return;
		for (file in sys.FileSystem.readDirectory(resolved)) {
			if (file.endsWith('.hx') || file.endsWith('.lua') || file.endsWith('.hxc'))
				load('$resolved/$file');
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
				script.registerOwner();
		}
		var result:Dynamic = null;
		for (script in scripts)
			result = script.access.callFunction(name, args);
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
		script.errorHandler = (e) -> Trace.traceOnce('[ScriptHandler ERROR] $path → ${e.details()}');
		script.tryExecute(sys.io.File.getContent(path));
		return script;
	}

	function setupScript(script:RuleScript):Void {
		script.superInstance = owner;

		for (name => value in extraVars)
			script.access.setVariable(name, value);
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
		owner = null;
		for (script in luaScripts)
			script.destroy();
		luaScripts = null;
	}
}

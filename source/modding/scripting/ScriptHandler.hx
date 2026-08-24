package modding.scripting;

import hxscript.Script;
import hxscript.Environment;
import hxscript.Module;

class ScriptHandler {
	public static var globalEnv:Environment = new Environment();

	var scripts:Array<Script> = [];
	var luaScripts:Array<modding.scripting.lua.LuaScript> = [];

	var paths:Array<String> = [];
	var modifiedTimes:Array<Float> = [];
	var pendingPaths:Array<String> = [];

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
			for (script in scripts) {
				td.init(null, script.interp);
				var valueToSet = td.structural ? td : td.alias;
				script.variables.set(name, valueToSet);
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
			if (script.variables.exists(name))
				result = script.call(name, args);
		}
		for (script in luaScripts)
			result = script.call(name, args);
		return result;
	}

	public function callCancellable(name:String, args:Array<Dynamic>):Bool {
		if (scripts == null)
			return false;
		for (script in scripts) {
			if (script.variables.exists(name)) {
				var result = script.call(name, args);
				if (result == true)
					return true;
			}
		}
		for (script in luaScripts) {
			if (script.callCancellable(name, args))
				return true;
		}
		return false;
	}

	public function exposeStatics(cls:Class<Dynamic>):Void {
		for (field in Type.getClassFields(cls))
			setVar(field, Reflect.getProperty(cls, field));
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

	function buildScript(path:String):Null<Script> {
		var content:String;
		try {
			content = sys.io.File.getContent(path);
		} catch (e) {
			Trace.traceOnce('[${haxe.io.Path.withoutDirectory(path)}] Cannot read file: ${e.message}');
			return null;
		}

		var scriptName = haxe.io.Path.withoutDirectory(path);
		var script = new Script(content, scriptName, globalEnv);

		script.onParsingError = function(e) {
			Trace.traceOnce('[$scriptName] Parse error: ${e.message}');
		};
		script.onProgramError = function(e) {
			var d = hxscript.error.Sink.history[hxscript.error.Sink.history.length - 1];
			var line = d != null ? '${d.line}' : '?';
			Trace.traceOnce('[$scriptName:$line] Script error: ${e.message}');
		};

		setupScript(script);
		script.start();

		return script;
	}

	function setupScript(script:Script):Void {
		var interp = Std.downcast(script.interp, modding.scripting.GameInterp);
		if (interp != null)
			interp.setContext(superInstance);

		script.variables.set('this', superInstance);
		for (name => value in extraVars)
			script.variables.set(name, value);
	}

	function setVar(name:String, value:Dynamic):Void {
		for (script in scripts)
			script.variables.set(name, value);
	}

	function reload(i:Int):Void {
		var content = sys.io.File.getContent(paths[i]);
		scripts[i].parse(content);
		setupScript(scripts[i]);
		scripts[i].start();
		modifiedTimes[i] = sys.FileSystem.stat(paths[i]).mtime.getTime();
		scripts[i].call('postCreate', []);
		Trace.traceOnce('[ScriptHandler] hot-reloaded: ${paths[i]}');
	}

	public function destroy():Void {
		if (scripts != null) {
			for (script in scripts) {
				@:privateAccess script.interp.variables = new hxscript.runtime.Bindings();
				var interp = Std.downcast(script.interp, GameInterp);
				if (interp != null)
					interp.setContext(null);
			}
		}
		scripts = null;
		paths = null;
		modifiedTimes = null;
		extraVars = null;
		superInstance = null;
		for (script in luaScripts)
			script.destroy();
		pendingPaths = null;
		luaScripts = null;
	}
}

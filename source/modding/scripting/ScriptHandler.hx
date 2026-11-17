package modding.scripting;

import hxscript.Script;
import hxscript.Module;

class ScriptHandler {
	public static var globalEnv:ScriptEnvironment = new ScriptEnvironment();

	var scripts:Array<Script> = [];
	var luaScripts:Array<modding.scripting.lua.LuaScript> = [];

	public static var moduleRegistry:Map<String, Module> = [];

	var paths:Array<String> = [];
	var modifiedTimes:Array<Float> = [];
	var pendingPaths:Array<String> = [];

	var superInstance:Dynamic;
	var extraVars:Map<String, Dynamic> = [];

	var callCache:Map<String, Array<{script:Script, fun:Dynamic}>> = new Map();

	public var hasScripts(get, never):Bool;

	inline function get_hasScripts():Bool
		return scripts.length > 0 || luaScripts.length > 0;

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
		Console.log('[ScriptHandler] find: $path');
	}

	public function loadFolder(folder:String):Void {
		var baseDir = '${core.assets.Library.baseFolder}/$folder';
		var modDir:String = null;

		if (modding.mods.ModsRegistry.onMod && modding.mods.ModsRegistry.currentMod != null && modding.mods.ModsRegistry.currentMod != '')
			modDir = '${core.assets.Library.modsFolder}/${modding.mods.ModsRegistry.currentMod}/$folder';

		var files:Map<String, String> = new Map();
		if (sys.FileSystem.exists(baseDir) && sys.FileSystem.isDirectory(baseDir)) {
			for (file in sys.FileSystem.readDirectory(baseDir)) {
				if (file.endsWith('.hx') || file.endsWith('.lua') || file.endsWith('.hxc'))
					files.set(file, '$baseDir/$file');
			}
		}

		if (modDir != null && sys.FileSystem.exists(modDir) && sys.FileSystem.isDirectory(modDir)) {
			for (file in sys.FileSystem.readDirectory(modDir)) {
				if (file.endsWith('.hx') || file.endsWith('.lua') || file.endsWith('.hxc'))
					files.set(file, '$modDir/$file');
			}
		}

		for (resolve => path in files)
			load(path);
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

	public static function loadModuleFile(filePath:String, ?knownPath:String):Null<Module> {
		if (moduleRegistry.exists(filePath))
			return moduleRegistry.get(filePath);

		var content:String;
		try {
			content = sys.io.File.getContent(filePath);
		} catch (e) {
			Console.log('[ScriptHandler] Could not be read $filePath: ${e.message}');
			return null;
		}

		scanAndLoadImports(content, filePath);

		var fileName = haxe.io.Path.withoutDirectory(haxe.io.Path.withoutExtension(filePath));
		var pack = derivePackage(filePath);

		var mod = new Module(content, fileName, pack, filePath);
		mod.onParsingError = e -> Console.log('[$fileName] Parse error: ${e.message}');
		mod.onProgramError = e -> Console.log('[$fileName] Runtime error: ${e.message}');

		moduleRegistry.set(filePath, mod);
		globalEnv.addModule(mod);

		mod.init(globalEnv);
		mod.start(globalEnv);
		mod.startTypes(globalEnv);

		for (_ => type in mod.types)
			globalEnv.variables.set(type.name, type);

		Console.log('[ScriptHandler] module loaded: $filePath');
		return mod;
	}

	static function scanAndLoadImports(content:String, originPath:String):Void {
		// `import a.b.C;` or `import a.b.*;`
		var reg = ~/^[ \t]*import\s+([\w.]+)(\.\*)?;[ \t]*(\r?\n)?/gm;
		reg.map(content, function(r) {
			var importPath = r.matched(1);
			var filePath = globalEnv.importPathToFile(importPath);
			if (filePath != null && sys.FileSystem.exists(filePath) && !moduleRegistry.exists(filePath))
				loadModuleFile(filePath, importPath);
			return r.matched(0);
		});
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
		callCache.clear();

		#if hxscript_cppia
		if (hxscript.compile.Compiler.available) {
			var mods = [for (_ => m in moduleRegistry) m];
			if (mods.length > 0)
				hxscript.compile.Compiler.compile(globalEnv, mods);
		}
		#end
	}

	public function call(name:String, args:Array<Dynamic>):Dynamic {
		if (scripts == null)
			return null;

		var result:Dynamic = null;
		for (fn in hookFns(name))
			result = safeCall(fn.script, fn.fun, args);
		for (script in luaScripts)
			result = script.call(name, args);
		return result;
	}

	public function callCancellable(name:String, args:Array<Dynamic>):Bool {
		if (scripts == null)
			return false;

		for (fn in hookFns(name))
			if (safeCall(fn.script, fn.fun, args) == true)
				return true;
		for (script in luaScripts)
			if (script.callCancellable(name, args))
				return true;
		return false;
	}

	// cache empty hooks too, most run every frame and no script uses them -JloorDev
	function hookFns(name:String):Array<{script:Script, fun:Dynamic}> {
		var cached = callCache.get(name);
		if (cached != null)
			return cached;

		var fns:Array<{script:Script, fun:Dynamic}> = [];
		for (script in scripts) {
			if (script.variables.exists(name)) {
				var fun = script.variables.get(name);
				if (Reflect.isFunction(fun))
					fns.push({script: script, fun: fun});
			}
		}
		callCache.set(name, fns);
		return fns;
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
		callCache.clear();
	}

	function buildScript(path:String):Null<Script> {
		var rawContent:String;
		try {
			rawContent = sys.io.File.getContent(path);
		} catch (e) {
			Console.log('[${haxe.io.Path.withoutDirectory(path)}] Cannot read file: ${e.message}');
			return null;
		}

		scanAndLoadImports(rawContent, path);

		var importReg = ~/^[ \t]*import\s+([\w.]+)(\.\*)?;[ \t]*(\r?\n)?/gm;
		var content = importReg.map(rawContent, function(r) {
			var importPath = r.matched(1);
			var filePath = globalEnv.importPathToFile(importPath);
			return (filePath != null && sys.FileSystem.exists(filePath)) ? '' : r.matched(0);
		});

		var scriptName = haxe.io.Path.withoutDirectory(path);
		var script = new Script(content, scriptName, globalEnv);

		script.onParsingError = function(e) {
			Console.log('[$scriptName] Parse error: ${e.message}');
		};
		script.onProgramError = function(e) {
			var d = hxscript.error.Sink.history[hxscript.error.Sink.history.length - 1];
			var line = d != null ? '${d.line}' : '?';
			Console.log('[$scriptName:$line] Script error: ${e.message}');
		};

		setupScript(script);
		script.start();

		return script;
	}

	static function derivePackage(filePath:String):Array<String> {
		var base = core.assets.Library.baseFolder + '/';
		var rel = filePath.startsWith(base) ? filePath.substr(base.length) : filePath;

		var mod = modding.mods.ModsRegistry.currentMod;
		if (mod != null) {
			var modBase = core.assets.Library.modsFolder + '/$mod/';
			if (filePath.startsWith(modBase))
				rel = filePath.substr(modBase.length);
		}
		var parts = haxe.io.Path.withoutExtension(rel).split('/');
		parts.pop();
		return parts.filter(p -> p.length > 0);
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
		#if hxscript_cppia
		hxscript.compile.Compiler.reset();
		#end
		if (moduleRegistry.exists(paths[i]))
			moduleRegistry.get(paths[i]).snapshot();

		var content = sys.io.File.getContent(paths[i]);
		scripts[i].parse(content);
		scripts[i].start();
		setupScript(scripts[i]);
		modifiedTimes[i] = sys.FileSystem.stat(paths[i]).mtime.getTime();
		scripts[i].call('postCreate', []);
		Console.log('[ScriptHandler] hot-reloaded: ${paths[i]}');
	}

	function safeCall(script:Script, fun:Dynamic, args:Array<Dynamic>):Dynamic {
		try {
			return Reflect.callMethod(script.interp, fun, args);
		} catch (e:haxe.Exception) {
			var line:String = '?';
			if (Std.isOfType(e, hxscript.error.InterpException)) {
				var d = (cast e : hxscript.error.InterpException).toDiagnostic();
				if (d.line > 0)
					line = '${d.line}';
			}
			Console.log('[${script.name}:$line] Runtime error: ${e.message}');
			return null;
		}
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
		callCache = null;
		extraVars = null;
		superInstance = null;
		for (script in luaScripts)
			script.destroy();
		pendingPaths = null;
		luaScripts = null;
	}
}

package core.scripting;

import states.MusicBeatState;
import rulescript.RuleScript;

class ScriptCore {
	public static var sharedContext:rulescript.Context = new rulescript.Context();

	var scripts:Array<RuleScript> = [];
	var paths:Array<String> = [];
	var modifiedTimes:Array<Float> = [];
	var state:MusicBeatState;

	var pendingPaths:Array<String> = [];

	public function new(state:MusicBeatState) {
		this.state = state;
	}

	public function load(path:String) {
		if (path == null || !sys.FileSystem.exists(path))
			return;
		pendingPaths.push(path);
		Trace.traceOnce('Script added to load: $path');
	}

	public function executeAll() {
		for (path in pendingPaths) {
			var parser = new rulescript.parsers.HxParser();
			parser.allowAll();
			var script = new RuleScript(parser, sharedContext);
			setupScript(script);
			script.errorHandler = (e) -> Trace.traceOnce('[ERROR] $path → ${e.details()}');
			script.execute(sys.io.File.getContent(path));
			scripts.push(script);
			paths.push(path);
			modifiedTimes.push(sys.FileSystem.stat(path).mtime.getTime());
		}
		pendingPaths = [];
	}

	public function exposeStatics(cls:Class<Dynamic>) {
		for (field in Type.getClassFields(cls)) {
			var value = Reflect.getProperty(cls, field);
			for (script in scripts)
				script.access.setVariable(field, value);
		}
	}

	public function call(name:String, args:Array<Dynamic>):Dynamic {
		var result:Dynamic = null;
		for (script in scripts)
			result = script.access.callFunction(name, args);
		return result;
	}

	public function hotReload() {
		for (i in 0...paths.length) {
			if (!sys.FileSystem.exists(paths[i]))
				continue;
			var modified = sys.FileSystem.stat(paths[i]).mtime.getTime();
			if (modified > modifiedTimes[i])
				reload(i);
		}
	}

	function reload(i:Int) {
		scripts[i].access.resetInterp();
		setupScript(scripts[i]);
		scripts[i].tryExecute(sys.io.File.getContent(paths[i]));
		modifiedTimes[i] = sys.FileSystem.stat(paths[i]).mtime.getTime();
		scripts[i].access.callFunction("postCreate", []);
		Trace.traceOnce('Reload ${paths[i]}');
	}

	function setupScript(script:RuleScript) {
		script.superInstance = state;
		script.access.setVariable("add", (o:flixel.FlxBasic) -> state.add(o));
		script.access.setVariable("remove", (o:flixel.FlxBasic) -> state.remove(o));

		script.access.setVariable("FlxBar", flixel.ui.FlxBar);
		script.access.setVariable("LEFT_TO_RIGHT", flixel.ui.FlxBar.FlxBarFillDirection.LEFT_TO_RIGHT);
		script.access.setVariable("RIGHT_TO_LEFT", flixel.ui.FlxBar.FlxBarFillDirection.RIGHT_TO_LEFT);

		script.access.setVariable("PlayState", game.PlayState);
		script.access.setVariable("FlxG", flixel.FlxG);
		script.access.setVariable("FlxSprite", flixel.FlxSprite);
	}

	public function destroy() {
		scripts = null;
		paths = null;
		modifiedTimes = null;
		state = null;
	}
}

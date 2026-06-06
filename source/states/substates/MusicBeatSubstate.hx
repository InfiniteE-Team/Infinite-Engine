package states.substates;

import core.rhythm.TrackBeat;
import core.json.JsonWatcher;
import utils.InfoHelpDebug;
#if HSCRIPT_ALLOWED
import core.scripting.ScriptHandler;
#end

class MusicBeatSubstate extends flixel.FlxSubState {
	var tracker:TrackBeat = new TrackBeat();
	#if HSCRIPT_ALLOWED
	var script:ScriptHandler;
	#end

	var infoHelp:InfoHelpDebug;

	override function create():Void {
		#if HSCRIPT_ALLOWED
		if (script == null)
			initScript();
		// script.call("onCreate", []);
		#end
		super.create();

		if (Main.globalData.developerMode) {
			infoHelp = new InfoHelpDebug(FlxG.width - 300, 0, 0);
			add(infoHelp);
		}
	}

	#if HSCRIPT_ALLOWED
	function initScript() {
		script = new ScriptHandler(this);
		var theclass = Type.getClass(this);
		var className = Type.getClassName(theclass).split('.').pop();
		script.load(Paths.getPath(className, 'states'));
		script.exposeStatics(theclass);
	}
	#end

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (Main.globalData.developerMode) {
			#if HSCRIPT_ALLOWED
			script.hotReload();
			#end

			if (FlxG.keys.justPressed.F5) {
				MusicBeatSubstate.resetState();
			}
			if (FlxG.keys.justPressed.F4)
				infoHelp.openUI();
		}
		tracker.update();
		tracker.check(stepHit, beatHit);
	}

	public static function resetState():Void {
		if (Main.globalData.developerMode)
			JsonWatcher.updateSwitch();
		var parent = _parentState;
		var cls = Type.getClass(this);
		close();
		parent.openSubState(Type.createInstance(cls, []));
	}

	public function stepHit(step:Int):Void {
		#if HSCRIPT_ALLOWED
		script.call("onStepHit", [step]);
		#end
	}

	public function beatHit(beat:Float):Void {
		#if HSCRIPT_ALLOWED
		script.call("onBeatHit", [beat]);
		#end
	}

	override function destroy():Void {
		core.assets.Paths.clearCache();
		JsonWatcher.clear();
		#if HSCRIPT_ALLOWED
		script.call("onDestroy", []);
		script.destroy();
		script = null;
		#end
		infoHelp = null;
		core.assets.FunkinGlobalObjectReg.clear();
		super.destroy();
	}
}

package states.substates;

import core.json.JsonWatcher;
import utils.InfoHelpDebug;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end
import game.controllers.InputController;

class MusicBeatSubstate extends Substate {
	var t:core.rhythm.RhythmTracker;

	#if HSCRIPT_ALLOWED
	var script:ScriptHandler;
	#end

	var infoHelp:InfoHelpDebug;

	override function create():Void {
		#if HSCRIPT_ALLOWED
		if (script == null)
			initScript();
		#end
		super.create();

		t = new core.rhythm.RhythmTracker();

		if (core.ConfigMain.globalData.developerMode) {
			infoHelp = new InfoHelpDebug(FlxG.width - 300, 0, 0);
			add(infoHelp);
		}
	}

	#if HSCRIPT_ALLOWED
	function initScript() {
		var theclass = Type.getClass(this);
		var className = Type.getClassName(theclass).split('.').pop();

		script = new ScriptHandler(this);
		script.load(Paths.getPath(className, 'substates'));
		script.exposeStatics(theclass);
		script.executeAll();
	}
	#end

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (core.ConfigMain.globalData.developerMode) {
			#if HSCRIPT_ALLOWED
			script.hotReload();
			#end

			if (FlxG.keys.justPressed.F4)
				infoHelp.openUI();
		}

		t.check(stepHit, beatHit);
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
		JsonWatcher.clear();
		#if HSCRIPT_ALLOWED
		script.call("onDestroy", []);
		script.destroy();
		script = null;
		#end
		infoHelp = null;

		t.reset();

		super.destroy();
	}
}

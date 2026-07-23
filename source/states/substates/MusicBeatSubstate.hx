package states.substates;

import core.rhythm.TrackBeat;
import core.json.JsonWatcher;
import utils.InfoHelpDebug;
#if HSCRIPT_ALLOWED
import core.scripting.ScriptHandler;
#end
import game.controllers.InputController;

class MusicBeatSubstate extends Substate {
	var tracker:TrackBeat = new TrackBeat();
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

		if (core.ConfigMain.globalData.developerMode) {
			infoHelp = new InfoHelpDebug(FlxG.width - 300, 0, 0);
			add(infoHelp);
		}
	}

	#if HSCRIPT_ALLOWED
	function initScript() {
		script = new ScriptHandler(this);
		var theclass = Type.getClass(this);
		var className = Type.getClassName(theclass).split('.').pop();
		script.load(Paths.getPath(className, 'substates'));
		script.exposeStatics(theclass);
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

		tracker.update();
		tracker.check(stepHit, beatHit);
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
		super.destroy();
	}
}

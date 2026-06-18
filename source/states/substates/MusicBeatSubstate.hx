package states.substates;

import core.rhythm.RhythmCore;
import flixel.addons.sound.FlxRhythmConductor;
import core.json.JsonWatcher;
import utils.InfoHelpDebug;
#if HSCRIPT_ALLOWED
import core.scripting.ScriptHandler;
#end
import game.controllers.InputController;

class MusicBeatSubstate extends flixel.FlxSubState {
	#if HSCRIPT_ALLOWED
	var script:ScriptHandler;
	#end

	var infoHelp:InfoHelpDebug;

	var input:InputController = new InputController();

	override function create():Void {
		#if HSCRIPT_ALLOWED
		if (script == null)
			initScript();
		#end
		super.create();

		FlxRhythmConductor.instance.onStepHit.add(_onStepHit);
        FlxRhythmConductor.instance.onBeatHit.add(_onBeatHit);
        FlxRhythmConductor.instance.onMeasureHit.add(_onMeasureHit);

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
		script.load(Paths.getPath(className, 'states'));
		script.exposeStatics(theclass);
	}
	#end

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (core.ConfigMain.globalData.developerMode) {
			#if HSCRIPT_ALLOWED
			script.hotReload();
			#end
/*
			if (FlxG.keys.justPressed.F5) {
				MusicBeatSubstate.resetState();
			}*/
			if (FlxG.keys.justPressed.F4)
				infoHelp.openUI();
		}
	}

	function _onStepHit(step:Int, backward:Bool):Void {
        if (!backward) stepHit(step);
    }

    function _onBeatHit(beat:Int, backward:Bool):Void {
        if (!backward) beatHit(beat);
    }

    function _onMeasureHit(measure:Int, backward:Bool):Void {
        if (!backward) measureHit(measure);
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

	public function measureHit(measure:Int):Void {}

	override function destroy():Void {
		FlxRhythmConductor.instance.onStepHit.remove(_onStepHit);
        FlxRhythmConductor.instance.onBeatHit.remove(_onBeatHit);
        FlxRhythmConductor.instance.onMeasureHit.remove(_onMeasureHit);
		
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

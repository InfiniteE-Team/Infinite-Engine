package states;

import states.LoadingState;
import core.rhythm.TrackBeat;
import core.json.JsonWatcher;
import states.menus.FreeplayState;
import utils.InfoHelpDebug;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end
import game.controllers.InputController;

class MusicBeatState extends State {
	public static var skipNextTransIn:Bool = false;
    public static var skipNextTransOut:Bool = false;

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

		if (core.ConfigMain.globalData.developerMode) {
			infoHelp = new InfoHelpDebug(FlxG.width - 300, 0, 0);
			add(infoHelp);
		}

		var isGlobalSkip = core.ConfigMain.globalData != null && core.ConfigMain.globalData.skipTrans == true;
        var skipIn = skipNextTransIn || isGlobalSkip;

		if (skipIn) {
            skipNextTransIn = false;
            return;
        }

		openSubState(new states.custom.CustomTransition(true, 0.2));
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
			if (FlxG.keys.justPressed.F5) {
				MusicBeatState.resetState();
				#if HSCRIPT_ALLOWED
				script.hotReload();
				#end
			}
			if (FlxG.keys.justPressed.F4)
				infoHelp.openUI();
		}

		tracker.update();
		tracker.check(stepHit, beatHit);
	}

	public static function resetState():Void {
		if (core.ConfigMain.globalData.developerMode)
			JsonWatcher.updateSwitch();
		FlxG.resetState();
	}

	public static function switchState(state:() -> MusicBeatState):Void {
		if (core.ConfigMain.globalData.developerMode)
			JsonWatcher.updateSwitch();

		var currentState = FlxG.state;

		var isGlobalSkip = core.ConfigMain.globalData != null && core.ConfigMain.globalData.skipTrans == true;
        var skipOut = skipNextTransOut || isGlobalSkip;

		if (skipOut) {
            skipNextTransOut = false;
            FlxG.switchState(state);
            return;
        }

        if (currentState != null) {
            currentState.openSubState(new states.custom.CustomTransition(false, 0.2, function() {
                FlxG.switchState(state);
            }));
        } else {
            FlxG.switchState(state);
        }
	}

	public function stepHit(step:Int) {
		#if HSCRIPT_ALLOWED
		script.call("onStepHit", [step]);
		#end

		if (core.ConfigMain.globalData.developerMode)
			infoHelp.text = 'Steps: $step';
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
		if (script != null) {
			script.call("onDestroy", []);
			script.destroy();
			script = null;
		}
		#end
		infoHelp = null;
		super.destroy();
	}
}

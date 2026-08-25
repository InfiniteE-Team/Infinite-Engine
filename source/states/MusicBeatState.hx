package states;

import states.LoadingState;
import core.json.JsonWatcher;
import states.menus.FreeplayState;
import utils.InfoHelpDebug;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end
import game.controllers.InputController;

class MusicBeatState extends State {
	public static var nextStickerPack:String = null;
	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	var t:core.rhythm.RhythmTracker;

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

		t = new core.rhythm.RhythmTracker();

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
		/*
			var pack = MusicBeatState.nextStickerPack;
			MusicBeatState.nextStickerPack = null;

			if (pack != null && pack.length > 0) {
				modding.custom.transitions.StickerOverlay.instance().leave();
		} else {*/
		var isGlobalSkip = core.ConfigMain.globalData != null && core.ConfigMain.globalData.skipTrans == true;
		if (!skipNextTransIn && !isGlobalSkip)
			openSubState(new modding.custom.transitions.CustomTransition(true, 0.2));
		skipNextTransIn = false;
		// }
	}

	#if HSCRIPT_ALLOWED
	function initScript() {
		var theclass = Type.getClass(this);
		var className = Type.getClassName(theclass).split('.').pop();

		script = new ScriptHandler(this);
		script.load(Paths.getPath(className, 'states'));
		script.exposeStatics(theclass);
		script.executeAll();
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

		t.check(stepHit, beatHit);
	}

	public static function resetState():Void {
		if (core.ConfigMain.globalData.developerMode)
			JsonWatcher.updateSwitch();
		FlxG.resetState();
	}

	public static function switchState(state:() -> MusicBeatState, ?packName:String = null):Void {
		if (core.ConfigMain.globalData.developerMode)
			JsonWatcher.updateSwitch();

		var isGlobalSkip = core.ConfigMain.globalData != null && core.ConfigMain.globalData.skipTrans == true;
		var skipOut = skipNextTransOut || isGlobalSkip;

		if (skipOut) {
			skipNextTransOut = false;
			FlxG.switchState(state);
			return;
		}
		/*
			nextStickerPack = packName;

			if (packName != null && packName.length > 0) {
				modding.custom.transitions.StickerOverlay.instance().show(packName, function() {
					FlxG.switchState(state);
				});
		} else {*/
		if (FlxG.state != null) {
			FlxG.state.openSubState(new modding.custom.transitions.CustomTransition(false, 0.2, function() {
				FlxG.switchState(state);
			}));
		}
		/*else {
				FlxG.switchState(state);
			}
		}*/
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
		t.reset();
		super.destroy();
	}
}

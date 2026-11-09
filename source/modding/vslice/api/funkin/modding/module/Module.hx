package funkin.modding.module;

// V-Slice Module: a script that gets every gameplay event -JloorDev
@:scriptable
@:keepSub
@:keep
class Module {
	public var moduleId:String;
	public var priority:Int;
	public var active:Bool = true;
	public var params:Dynamic;

	public function new(id:String, priority:Int = 1000, ?params:Dynamic) {
		moduleId = id;
		this.priority = priority;
		this.params = params;
	}

	// `{state: X}` keeps a module to one state; hxscript turns a bare PlayState into the engine's class -JloorDev
	public function runsInGameplay():Bool {
		if (params == null || !Reflect.hasField(params, 'state'))
			return true;
		return params.state == funkin.play.PlayState || params.state == game.PlayState;
	}

	public function onCreate(e:Dynamic):Void {}

	public function onDestroy(e:Dynamic):Void {}

	public function onUpdate(e:Dynamic):Void {}

	public function onBeatHit(e:Dynamic):Void {}

	public function onStepHit(e:Dynamic):Void {}

	public function onCountdownStart(e:Dynamic):Void {}

	public function onCountdownStep(e:Dynamic):Void {}

	public function onCountdownEnd(e:Dynamic):Void {}

	public function onSongStart(e:Dynamic):Void {}

	public function onSongEnd(e:Dynamic):Void {}

	public function onSongRetry(e:Dynamic):Void {}

	public function onSongEvent(e:Dynamic):Void {}

	public function onSongLoaded(e:Dynamic):Void {}

	public function onNoteHit(e:Dynamic):Void {}

	public function onNoteMiss(e:Dynamic):Void {}

	public function onNoteIncoming(e:Dynamic):Void {}

	public function onNoteHoldDrop(e:Dynamic):Void {}

	public function onNoteGhostMiss(e:Dynamic):Void {}

	public function onPause(e:Dynamic):Void {}

	public function onResume(e:Dynamic):Void {}

	public function onGameOver(e:Dynamic):Void {}

	public function onStateChangeBegin(e:Dynamic):Void {}

	public function onStateChangeEnd(e:Dynamic):Void {}

	public function onSubStateOpenBegin(e:Dynamic):Void {}

	public function onSubStateOpenEnd(e:Dynamic):Void {}

	public function onSubStateCloseBegin(e:Dynamic):Void {}

	public function onSubStateCloseEnd(e:Dynamic):Void {}

	public function onFocusGained(e:Dynamic):Void {}

	public function onFocusLost(e:Dynamic):Void {}

	public function onScriptEvent(e:Dynamic):Void {}

	public function toString():String
		return 'Module($moduleId)';
}

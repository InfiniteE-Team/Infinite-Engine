package funkin.play.song;

// V-Slice Song for song scripts (data/songs/<id> cutscenes, intros, outros): just the id and the hooks -JloorDev
@:scriptable
@:keepSub
@:keep
class Song {
	public var id:String;

	public function new(id:String) {
		this.id = id;
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

	public function onFocusGained(e:Dynamic):Void {}

	public function onFocusLost(e:Dynamic):Void {}

	public function onScriptEvent(e:Dynamic):Void {}
}

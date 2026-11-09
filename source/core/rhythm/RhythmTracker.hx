package core.rhythm;

class RhythmTracker {
	public var step(get, never):Int;
	public var beat(get, never):Float;

	private var lastStep:Int = -1;
	private var lastBeat:Int = -1;

	private var stepOffset:Int = 0;
	private var timeAtBpmChange:Float = 0;

	inline function get_step():Int
		return stepOffset + Math.floor((core.rhythm.RhythmCore.songPosition - timeAtBpmChange) / core.rhythm.RhythmCore.stepInMs);

	inline function get_beat():Int
		return step >> 2;

	public function new() {}

	public function onBpmChange():Void {
		stepOffset = step;
		timeAtBpmChange = core.rhythm.RhythmCore.songPosition;
	}

	public function check(onStep:Int->Void, onBeat:Float->Void):Void {
		var curStep:Int = step;

		if (curStep > lastStep) {
			onStep(lastStep = curStep);

			var curBeat:Float = beat;
			if (curBeat > lastBeat) {
				onBeat(lastBeat = Std.int(curBeat));
			}
		}
	}

	// call after moving songPosition back, so the countdown's negative beats still fire -JloorDev
	public function syncTo():Void {
		lastStep = step - 1;
		lastBeat = lastStep >> 2;
	}

	public function reset():Void {
		lastStep = lastBeat = -1;
		stepOffset = 0;
		timeAtBpmChange = 0;
	}
}

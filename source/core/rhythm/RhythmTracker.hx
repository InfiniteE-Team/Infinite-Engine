package core.rhythm;

class RhythmTracker {
	public var step(get, never):Int;
	public var beat(get, never):Float;

	private var lastStep:Int = -1;
	private var lastBeat:Int = -1;

	inline function get_step():Int
		return Std.int(core.rhythm.RhythmCore.songPosition / core.rhythm.RhythmCore.stepInMs);

	inline function get_beat():Int
		return step >> 2;

	public function new() {}

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

	public function reset():Void
		lastStep = lastBeat = -1;
}

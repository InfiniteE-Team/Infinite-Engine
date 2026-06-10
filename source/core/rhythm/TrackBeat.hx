package core.rhythm;

class TrackBeat {
	private var step:Int = 0;
	private var beat:Float = 0;
	private var lastBeat:Float = -1;
	private var lastStep:Float = -1;

	public function new() {}

	public function update():Void {
		step = Math.floor(RhythmCore.songPosition / RhythmCore.stepInMs);
		beat = Math.floor(step / 4);
	}

	public function check(onStep:Int->Void, onBeat:Float->Void):Void {
		if (step > lastStep) {
			lastStep = step;
			onStep(step);
			if (beat > lastBeat) {
				lastBeat = beat;
				onBeat(beat);
			}
		}
	}

	public function reset():Void {
		step = 0;
		beat = 0;
		lastStep = -1;
		lastBeat = -1;
	}
}

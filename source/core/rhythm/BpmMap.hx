package core.rhythm;

// a song's tempo as stretches of constant BPM, built from the base BPM and its "Change BPM" events
// turns ms into steps and back across those changes, one bpm for the whole song can't -JloorDev
class BpmMap {
	var times:Array<Float> = [];
	var steps:Array<Float> = [];
	var stepMs:Array<Float> = [];

	public function new(baseBpm:Float, ?events:Array<core.json.song.SongData.EventsData>) {
		add(0, baseBpm);
		if (events == null)
			return;

		var changes = [for (e in events) if (e.name == 'Change BPM' && e.time > 0) e];
		changes.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
		for (e in changes) {
			var bpm = Std.parseFloat(Std.string(Reflect.field(e.arguments, 'bpm')));
			if (!Math.isNaN(bpm) && bpm > 0)
				add(e.time, bpm);
		}
	}

	function add(time:Float, bpm:Float):Void {
		var last = times.length - 1;
		var step = last < 0 ? 0 : steps[last] + (time - times[last]) / stepMs[last];
		// two changes on the same ms, the later one wins -JloorDev
		if (last >= 0 && times[last] == time) {
			stepMs[last] = 15000 / bpm;
			return;
		}
		times.push(time);
		steps.push(step);
		stepMs.push(15000 / bpm);
	}

	// the stretch that holds this ms (or step), the first one also covers what's before 0 -JloorDev
	function indexAt(values:Array<Float>, v:Float):Int {
		var i = values.length - 1;
		while (i > 0 && values[i] > v)
			i--;
		return i;
	}

	public function stepAt(ms:Float):Float {
		var i = indexAt(times, ms);
		return steps[i] + (ms - times[i]) / stepMs[i];
	}

	public function timeAt(step:Float):Float {
		var i = indexAt(steps, step);
		return times[i] + (step - steps[i]) * stepMs[i];
	}

	public function bpmAt(ms:Float):Float
		return 15000 / stepMs[indexAt(times, ms)];

	public function stepLengthAt(ms:Float):Float
		return stepMs[indexAt(times, ms)];

	public static function selfCheck():Void {
		var ev = (t:Float, bpm:Float) -> ({name: 'Change BPM', time: t, arguments: {bpm: bpm}} : core.json.song.SongData.EventsData);
		var map = new BpmMap(120, [ev(2000, 60)]);
		// 120 bpm: a step is 125 ms, so 2000 ms is step 16; then 60 bpm, 250 ms a step
		assertNear(map.stepAt(1000), 8);
		assertNear(map.stepAt(2000), 16);
		assertNear(map.stepAt(2500), 18);
		assertNear(map.timeAt(18), 2500);
		assertNear(map.timeAt(8), 1000);
		assertNear(map.bpmAt(3000), 60);
		var flat = new BpmMap(100);
		assertNear(flat.timeAt(flat.stepAt(1234)), 1234);
	}

	static function assertNear(a:Float, b:Float):Void
		if (Math.abs(a - b) > 0.001)
			throw 'BpmMap check failed: $a != $b';
}

package funkin.util;

import flixel.util.FlxTimer;

// V-Slice Sequence: callbacks at set times (seconds), the backbone of scripted cutscenes -JloorDev
@:keep
class Sequence {
	public var running(get, never):Bool;
	public var finished(default, null):Bool = false;

	var events:Array<Dynamic>;
	var mult:Float;
	var timers:Array<FlxTimer> = [];
	var paused:Bool = false;

	public function new(events:Array<Dynamic>, mult:Float = 1, start:Bool = true) {
		this.events = events ?? [];
		this.mult = mult;
		if (start)
			this.start();
	}

	public function start():Void {
		clear();
		finished = false;
		var left = events.length;
		if (left == 0) {
			finished = true;
			return;
		}
		for (e in events) {
			var callback:Void->Void = e.callback;
			timers.push(new FlxTimer().start(Math.max(0, (e.time ?? 0) * mult), _ -> {
				if (callback != null)
					callback();
				if (--left <= 0)
					finished = true;
			}));
		}
	}

	function get_running():Bool
		return !finished && !paused && timers.length > 0;

	public function pause():Void {
		paused = true;
		for (t in timers)
			t.active = false;
	}

	public function resume():Void {
		paused = false;
		for (t in timers)
			t.active = true;
	}

	public function clear():Void {
		for (t in timers)
			t.cancel();
		timers = [];
	}

	public function destroy():Void {
		clear();
		events = null;
	}
}

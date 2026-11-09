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
			// with `?? 0` haxe typed it Int and 0.24 secs fired at once -JloorDev
			var time:Float = e.time ?? 0.0;
			timers.push(new FlxTimer().start(Math.max(0, time * mult), _ -> {
				// runs from a timer, a script error here would crash the game -JloorDev
				if (callback != null)
					try {
						callback();
					} catch (err:Dynamic) {
						Console.log('[V-Slice] a Sequence callback failed: $err', true);
					}
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

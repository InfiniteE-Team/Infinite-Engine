package funkin;

import core.rhythm.RhythmCore;

// V-Slice's Conductor.instance, read from the engine's RhythmCore -JloorDev
@:keep
class Conductor {
	public static var instance(default, null):Conductor = new Conductor();

	public static var stepHit(default, null):flixel.util.FlxSignal = new flixel.util.FlxSignal();
	public static var beatHit(default, null):flixel.util.FlxSignal = new flixel.util.FlxSignal();

	public var songPosition(get, never):Float;
	public var currentBeat(get, never):Int;
	public var currentStep(get, never):Int;
	public var beatLengthMs(get, never):Float;
	public var stepLengthMs(get, never):Float;
	public var bpm(get, never):Float;

	function new() {}

	public function update(?songPosition:Float, ?applyOffsets:Bool):Void {}

	public function getBeatTimeInMs(?beat:Float):Float {
		if (beat == null)
			beat = currentBeat;
		return RhythmCore.getBeatTimeInMs(beat);
	}

	public function getStepTimeInMs(?step:Float):Float {
		if (step == null)
			step = currentStep;
		return RhythmCore.getStepTimeInMs(step);
	}

	function get_songPosition():Float
		return RhythmCore.songPosition;

	function get_currentBeat():Int
		return Std.int(RhythmCore.songPosition / RhythmCore.crochet);

	function get_currentStep():Int
		return Std.int(RhythmCore.songPosition / RhythmCore.stepInMs);

	function get_beatLengthMs():Float
		return RhythmCore.crochet;

	function get_stepLengthMs():Float
		return RhythmCore.stepInMs;

	function get_bpm():Float
		return RhythmCore.bpm;
}

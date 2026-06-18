package core.rhythm;

import flixel.addons.sound.FlxRhythmConductor;
import flixel.addons.sound.MusicTimeChangeEvent;

class RhythmCore {
	public static var conductor(get, never):FlxRhythmConductor;

	static inline function get_conductor():FlxRhythmConductor
		return FlxRhythmConductor.instance;

	public static var bpm(get, never):Float;

	static inline function get_bpm():Float
		return conductor.currentBpm;

	public static var crochet(get, never):Float;

	static inline function get_crochet():Float
		return conductor.beatLengthMs;

	public static var stepInMs(get, never):Float;

	static inline function get_stepInMs():Float
		return conductor.stepLengthMs;

	public static var onStepHit(get, never):flixel.util.FlxSignal.FlxTypedSignal<(Int, Bool) -> Void>;

	static inline function get_onStepHit()
		return FlxRhythmConductor.stepHit;

	public static var onBeatHit(get, never):flixel.util.FlxSignal.FlxTypedSignal<(Int, Bool) -> Void>;

	static inline function get_onBeatHit()
		return FlxRhythmConductor.beatHit;

	public static var onMeasureHit(get, never):flixel.util.FlxSignal.FlxTypedSignal<(Int, Bool) -> Void>;

	static inline function get_onMeasureHit()
		return FlxRhythmConductor.measureHit;

	public static var onBpmChange(get, never):flixel.util.FlxSignal.FlxTypedSignal<Float->Void>;

	static inline function get_onBpmChange()
		return FlxRhythmConductor.bpmChange;

	public static function changeBPM(newBPM:Float):Void {
		setupTimeChanges([new MusicTimeChangeEvent(0.0, newBPM)]);
	}

	public static function setupTimeChanges(timeChanges:Array<MusicTimeChangeEvent>):Void {
		conductor.setupTimeChanges(timeChanges);
	}

	public static function setTarget(sound:flixel.sound.FlxSound):Void {
		conductor.target = sound;
	}

	public static var songPosition(get, set):Float;

	static inline function get_songPosition():Float
		return conductor.musicPosition;

	static function set_songPosition(value:Float):Float {
		conductor.update(value);
		return value;
	}

	public static function pause(gameAudio:core.rhythm.audio.GameAudio, windowMod):Void {
		FlxG.sound.pause();
		if (gameAudio.inst != null)
			gameAudio.inst.pause();
		if (gameAudio.vocals != null)
			gameAudio.vocals.pause();
		if (windowMod != null)
			windowMod.pauseWindow();
	}

	public static function resume(gameAudio:core.rhythm.audio.GameAudio, windowMod):Void {
		FlxG.sound.resume();
		if (gameAudio.inst != null) {
			gameAudio.inst.resume();
			if (gameAudio.vocals != null) {
				// gameAudio.vocals.time = gameAudio.inst.time;
				gameAudio.vocals.resume();
			}
		}
		if (windowMod != null)
			windowMod.resumeWindow();
	}

	public static function reset(bpm:Float):Void {
		changeBPM(bpm);
		conductor.update(0.0);
	}
}

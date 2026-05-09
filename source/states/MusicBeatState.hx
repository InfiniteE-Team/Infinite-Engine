package states;
import flixel.FlxState;
import core.rhythm.RhythmCore;

class MusicBeatState extends FlxState {
    private var step:Float = 0;
    private var beat:Float = 0;
    private var lastBeat:Float = -1;

    override function create():Void {
        super.create();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        updateStep();
        updateBeat();
        stepHit();
    }

    public function updateBeat():Void
	{
		beat = Math.floor(step / 4);
	}

    public function updateStep():Void {
        step = RhythmCore.songPosition / RhythmCore.stepInMs;
        beat = step / 4;
    }

    public function stepHit():Void
	{
        if (beat > lastBeat) {
            lastBeat = beat;
            beatHit();
        }
	}

    public function beatHit():Void {
    }

    override function destroy():Void {
		super.destroy();
	}
}
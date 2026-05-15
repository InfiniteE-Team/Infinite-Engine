package states;
import flixel.FlxState;
import core.rhythm.RhythmCore;
import core.scripting.ScriptCore;

class MusicBeatState extends FlxState {
    private var step:Float = 0;
    private var beat:Float = 0;
    private var lastBeat:Float = -1;
    #if HSCRIPT_ALLOWED
    var script:ScriptCore;
    #end

    override function create():Void {
        #if HSCRIPT_ALLOWED
        if (script == null) initScript();
        //script.call("onCreate", []);
        #end
        super.create();
    }

    #if HSCRIPT_ALLOWED
    function initScript() {
        script = new ScriptCore(this);
        var className = Type.getClassName(Type.getClass(this)).split('.').pop();
        script.load(Paths.getPath(className, 'class'));
    }
    #end

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        
        if (Main.globalData.developerMode){
            #if HSCRIPT_ALLOWED
            script.hotReload();
            #end
            if (FlxG.keys.justPressed.F5)
                FlxG.resetState();
        }
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
        #if HSCRIPT_ALLOWED
        script.call("onStepHit", [step]);
        #end
	}

    public function beatHit():Void {
        #if HSCRIPT_ALLOWED
        script.call("onBeatHit", [beat]);
        #end
    }

    override function destroy():Void {
        #if HSCRIPT_ALLOWED
        script.call("onDestroy", []);
        #end
		super.destroy();
	}
}
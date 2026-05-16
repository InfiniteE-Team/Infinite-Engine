package states;
import flixel.FlxState;
import core.rhythm.RhythmCore;
import core.scripting.ScriptCore;
import utils.InfoHelpDebug;

class MusicBeatState extends FlxState {
    private var step:Int = 0;
    private var beat:Float = 0;
    private var lastBeat:Float = -1;
    private var lastStep:Float = -1;
    #if HSCRIPT_ALLOWED
    var script:ScriptCore;
    #end

    var infoHelp:InfoHelpDebug;

    override function create():Void {
        #if HSCRIPT_ALLOWED
        if (script == null) initScript();
        //script.call("onCreate", []);
        #end
        super.create();

        if (Main.globalData.developerMode)
        {
            infoHelp = new InfoHelpDebug(FlxG.width - 300,0,0);
            add(infoHelp);
        }
    }

    #if HSCRIPT_ALLOWED
    function initScript() {
        script = new ScriptCore(this);
        var theclass = Type.getClass(this);
        var className = Type.getClassName(theclass).split('.').pop();
        script.load(Paths.getPath(className, 'class'));
        script.exposeStatics(theclass);
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
            if (FlxG.keys.justPressed.F4)
                infoHelp.openUI();
        }
        updateStep();
        updateBeat();
        stepHit();
    }

    public function updateBeat():Void
	{
		beat = Math.floor(step / 4);
        if (Main.globalData.developerMode)
            infoHelp.text = 'Beats: $beat - Steps: $step';
	}

    public function updateStep():Void {
        step = Math.floor(RhythmCore.songPosition / RhythmCore.stepInMs);
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
        script.destroy();
        script = null;
        #end
        infoHelp = null;
		super.destroy();
	}
}
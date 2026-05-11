package;
import core.system.FPSCounter;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.events.Event;

import openfl.display.StageDisplayState;
import openfl.Lib;

import flixel.FlxState;
import game.PlayState;

class Main extends Sprite {
    public var fps:FPSCounter = new FPSCounter(5,5,0xFFFFFF);
    public var mainState:Class<FlxState> = PlayState;
    public function new() {
        super();
        addEventListener(Event.ADDED_TO_STAGE, added);
    }
    
    private function added(?e:Event):Void {
        if (hasEventListener(Event.ADDED_TO_STAGE))
            removeEventListener(Event.ADDED_TO_STAGE, added);
        mainGame();
    }

    function mainGame()
    {/*
        if (FlxG.keys.justPressed.F11)
            toggleFullscreen();*/
        addChild(new FlxGame(1280, 720, mainState, 60, 60, true, false));
        addChild(fps);
    }
/*
    function toggleFullscreen()
    {
        var stage = Lib.current.stage;

        switch (stage.displayState)
        {
            case FULL_SCREEN:
                stage.displayState = NORMAL;

            default:
                stage.displayState = FULL_SCREEN;
        }
    }*/
}
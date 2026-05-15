package;
import core.system.FPSCounter;
import core.system.WindowConfig;

import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageDisplayState;
import openfl.Lib;
import flixel.FlxState;
import game.PlayState;
import core.config.Controls;
import core.config.SaveData;

import core.json.engine.GlobalData.GlobalConfig;

class Main extends Sprite {
    public var fps:FPSCounter = new FPSCounter(5,5,0xFFFFFF);
    public var mainState:Class<FlxState> = PlayState;
    public static var save:SaveData;
    public static var controls:Controls;
    public static var globalData:GlobalConfig = new GlobalConfig();

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
    {
        configGame();
        addChild(new FlxGame(1280, 720, mainState, 60, 60, true, false));
        addChild(fps);
        if (FlxG.keys.justPressed.F11)
            toggleFullscreen();
        WindowConfig.applyAccentColor();
    }

    function configGame()
    {
        save = new SaveData();
        save.loadConfig();
        controls = new Controls(save);
        globalData.configGlobal();
    }

    public static function toggleFullscreen():Void
		FlxG.fullscreen = !FlxG.fullscreen;
}
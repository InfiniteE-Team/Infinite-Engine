package;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.events.Event;
import game.PlayState;

class Main extends Sprite {
    
    public function new() {
        super();
        addEventListener(Event.ADDED_TO_STAGE, added);
    }
    
    private function added(?e:Event):Void {
        if (hasEventListener(Event.ADDED_TO_STAGE))
            removeEventListener(Event.ADDED_TO_STAGE, added);
        addChild(new FlxGame(1280, 720, PlayState, 60, 60, true, false));
    }
}
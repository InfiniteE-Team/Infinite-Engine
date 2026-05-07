package game.objects;

import flixel.FlxSprite;

class Character extends FlxSprite {
    
    public function new(X:Float, Y:Float) {
        super(x,y);
    }
    
    function graphicLoad():FlxSprite {
        
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
    }
}
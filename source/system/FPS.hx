package system;
import flash.text.TextField;

class FPS extends TextField
{
    var currentFPS:Int = 0;
    public function new(x:Float,y:Float)
    {
        super();
        currentFPS = 0;
        text = "FPS: " + currentFPS;
        setTextFormat('_sans',24,FlxColor.WHITE,false);
    }
}

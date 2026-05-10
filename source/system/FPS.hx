package system;
import openfl.display.FPS;
import flash.text.TextField;
import openfl.system.System;
import openfl.events.Event;

class FPS extends openfl.display.FPS
{
    //var currentFPS:Int = 0;
    public function new(x:Float,y:Float,color:Int)
    {
        super(x,y,color);/*
        currentFPS = 0;
        text = "FPS: " + currentFPS;
        setTextFormat('_sans',24,FlxColor.WHITE,false);*/
    }

    @:noCompletion
    override private function __enterFrame(e:Float):Void
    {
        super.__enterFrame(e);
        var mem:Float = Math.round(System.totalMemory / 1024 / 1024 * 100) / 100;
        text = "FPS: " + currentFPS + "\nMEM: " + mem + " MB";
    }
}

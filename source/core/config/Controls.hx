package core.config;

class Controls
{
    public var inputNotes:Array<Bool> = [FlxG.keys.pressed.A, FlxG.keys.pressed.W, FlxG.keys.pressed.S, FlxG.keys.pressed.D];
    
    public function new() {}
    
    public function getInputNotes():Array<Bool> {
        return [
            FlxG.keys.pressed.A,
            FlxG.keys.pressed.W,
            FlxG.keys.pressed.S,
            FlxG.keys.pressed.D
        ];
    }
}
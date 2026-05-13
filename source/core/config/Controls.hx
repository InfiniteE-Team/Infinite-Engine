package core.config;
import flixel.input.keyboard.FlxKey;

class Controls {
    public var save:SaveData;
    public var noteKeys:Array<FlxKey> = [];

    public function new(save:SaveData) {
        this.save = save;
        noteKeys = [for (k in save.noteKeys) FlxKey.fromString(k)];
    }

    public function getInputNotes():Array<Bool>{
        @:privateAccess
        return [for (key in noteKeys) FlxG.keys.pressed.check(key)];
    }

    public function justPressedNote(i:Int):Bool{
        @:privateAccess
        return FlxG.keys.justPressed.check(noteKeys[i]);
    }

    public function justReleasedNote(i:Int):Bool{
        @:privateAccess
        return FlxG.keys.justReleased.check(noteKeys[i]);
    }

    public function setKey(index:Int, key:FlxKey):Void {
        if (index >= noteKeys.length) return;
        noteKeys[index] = key;
        save.noteKeys[index] = key.toString();
        save.saveConfig();
    }
}
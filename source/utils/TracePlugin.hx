package utils;

import flixel.FlxBasic;
import flixel.group.FlxSpriteGroup;

class TracePlugin extends FlxBasic {
    var group:FlxSpriteGroup;

    public function new(group:FlxSpriteGroup) {
        super();
        this.group = group;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        if (FlxG.cameras.list.length > 0)
            group.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        group.update(elapsed);
    }

    override function draw() {
        group.draw();
    }

    override function destroy() {
        group = null;
        super.destroy();
    }
}
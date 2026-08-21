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
package core.input.mobile;

@:keep
class TouchUtil {
    public static function justPressed(?area:flixel.FlxObject):Bool {
        #if mobile
        for (touch in FlxG.touches.list)
            if (touch.justPressed)
                return area == null || touch.overlaps(area);
        return false;
        #else
        return FlxG.mouse.justPressed && (area == null || FlxG.mouse.overlaps(area));
        #end
    }

    public static function pressed(?area:flixel.FlxObject):Bool {
        #if mobile
        for (touch in FlxG.touches.list)
            if (touch.pressed)
                return area == null || touch.overlaps(area);
        return false;
        #else
        return FlxG.mouse.pressed && (area == null || FlxG.mouse.overlaps(area));
        #end
    }

    public static function justReleased(?area:flixel.FlxObject):Bool {
        #if mobile
        for (touch in FlxG.touches.list)
            if (touch.justReleased)
                return area == null || touch.overlaps(area);
        return false;
        #else
        return FlxG.mouse.justReleased && (area == null || FlxG.mouse.overlaps(area));
        #end
    }

    public static function getPosition():flixel.math.FlxPoint {
        #if mobile
        for (touch in FlxG.touches.list)
            if (touch.pressed)
                return flixel.math.FlxPoint.weak(touch.x, touch.y);
        return flixel.math.FlxPoint.weak(0, 0);
        #else
        return FlxG.mouse.getPosition();
        #end
    }

    public static function touchesOver(area:flixel.FlxObject):Int {
        #if mobile
        var count = 0;
        for (touch in FlxG.touches.list)
            if (touch.pressed && touch.overlaps(area)) count++;
        return count;
        #else
        return (FlxG.mouse.pressed && FlxG.mouse.overlaps(area)) ? 1 : 0;
        #end
    }
}
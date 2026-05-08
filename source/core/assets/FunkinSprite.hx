package core.assets;

import animate.FlxAnimate;
import flixel.math.FlxPoint;

class FunkinSprite extends FlxAnimate {
    public var offsets:Map<String, FlxPoint> = new Map();

    override public function updateHitbox()
    {
        super.updateHitbox();
    }

    public function playAnim(name:Null<String>, ?force:Bool = true)
    {
        if (!existsAnim(name)){
            trace('$name Anim Not Existed! ERROR');
            return;
        }
        animation.play(name, force);
        activeOffsets(getAnimOffset());
    }

    public function getAnimOffset():FlxPoint
        return offsets.get(anim.name) ?? new FlxPoint();

    public function existsAnim(anim:String):Bool
        return animation.exists(anim);

    public function isFinished(anim:String):Bool
        return animation.curAnim.finished && existsAnim(anim);

    public function activeOffsets(offset:FlxPoint)
    {
        this.x += offset.x;
        this.y += offset.y;
    }
}
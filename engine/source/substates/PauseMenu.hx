
class PauseMenu extends ScriptSubstateBase
{
    override public function create()
    {
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxColor.BLACK,1280,720);
        bg.scrollFactor.set();
        bg.screenCenter();
        add(bg);



        super.create();
    }
}
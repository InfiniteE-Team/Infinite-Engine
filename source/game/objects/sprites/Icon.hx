class Icon extends FunkinSprite
{
    public function new(char:String = 'bf', isPlayer:Bool)
    {
        super();
        updateIcon();
    }

    public function updateIcon(char:String = 'bf', isPlayer:Bool)
    {
        loadGraphic(Paths.getPath('icons/$char','image'), true, 150, 150);
        animation.add('normal', [0], 0, false);
        animation.add('losing', [1], 0, false);
        updateHitbox();
    }
}
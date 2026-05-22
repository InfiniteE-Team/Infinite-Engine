package core.config;
import core.json.extensions.SpriteData;
import core.assets.FunkinSprite;

class CursorConfig extends FunkinSprite
{
    // yep

    var cursorProps:SpriteData.ObjectData;

    var cursorAnims:SpriteData.AnimData;

    public function new() {}

    public function loadCursor()
    {
		cursorProps = UtilsData.readJson(Paths.getPath('data/cursorConfig', "json"));

	    loadProps(cursorProps, 'characters');
    }
}
package states.menus.objects;

import core.json.extensions.SpriteData;

class WeekCharacter extends core.assets.FunkinSprite {
	var character:String = 'bf';
    var wCharacterData:ObjectData;

	public function new(x:Float, y:Float, ?character:String = 'bf') {
		super();
		this.x = x;
		this.y = y;
		this.character = character;
		setPosition(x, y);
        loadJson();
        loadSprite(character);
	}

	public function loadSprite(?character:String = 'bf') {
        loadProps(wCharacterData, 'menus/storymenu/chars');
		playAnim('idle', true);
    }

    public function loadJson() {
        wCharacterData = FormatJson.readJson(Paths.getPath('data/storymenu/chars/$character', 'json'));
    }

	public function acceptWeek() {
		playAnim('confirm', true);
	}
}

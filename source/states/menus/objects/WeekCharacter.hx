package states.menus.objects;

import core.json.extensions.SpriteData;

class WeekCharacter extends core.assets.FunkinSprite {
	var character:String = 'bf';
    var wCharacterData:ObjectData;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?props:ObjectData) {
		super();
		this.x = x;
		this.y = y;
		this.character = character;
		setPosition(x, y);
        if (props != null)
            wCharacterData = props;
        else
            loadJson();
        loadSprite(character);
	}

	public function loadSprite(?character:String = 'bf') {
        loadProps(wCharacterData, 'menus/storymenu/chars');
		dance();
    }

	var danced:Bool = false;

	override public function dance() {
		if (existsAnim('danceLeft') && existsAnim('danceRight')) {
			danced = !danced;
			playAnim(danced ? 'danceLeft' : 'danceRight', true);
		} else
			playAnim('idle', true);
	}

    public function loadJson() {
        wCharacterData = FormatJson.readJson(Paths.getPath('data/menus/storymenu/chars/$character', 'json'));
    }

	public function acceptWeek() {
		playAnim('confirm', true);
	}
}

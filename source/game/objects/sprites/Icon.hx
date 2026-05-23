package game.objects.sprites;

import core.json.objects.CharacterData;

class Icon extends FunkinSprite {
    public var bumpInBeats:Bool = true;
    public var stepTempo:Float = 1;
	public function new(isPlayer:Bool, characterData:CharacterData) {
		super();
		updateIcon(isPlayer, characterData);
	}

	public function updateIcon(isPlayer:Bool, characterData:CharacterData) {
		if (characterData.icon.props.position == null)
			return;

		bumpInBeats = characterData.icon.bumpInBeats ?? true;
		stepTempo = characterData.icon.stepTempo ?? 1;

		if (characterData.icon.props != null)
			setPosition(characterData.icon.props.position[0], characterData.icon.props.position[1]);

		loadProps(characterData.icon.props, 'icons');
	}
}

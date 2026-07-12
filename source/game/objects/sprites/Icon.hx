package game.objects.sprites;

import core.rhythm.TrackBeat;
import core.json.objects.CharacterData;

class Icon extends core.assets.FunkinSprite {
	public var bumpInBeats:Bool = true;
	public var stepTempo:Float = 1;

	public function new(isPlayer:Bool, characterData:CharacterData) {
		super();
		updateIcon(isPlayer, characterData);
	}

	public function updateIcon(isPlayer:Bool, characterData:CharacterData) {
		if (characterData.icon.props.position == null)
			characterData.icon.props.position = [0, 0];

		bumpInBeats = characterData.icon.bumpInBeats ?? true;
		stepTempo = characterData.icon.stepTempo ?? 1;

		if (characterData.icon.props != null)
			setPosition(characterData.icon.props.position[0], characterData.icon.props.position[1]);

		loadProps(characterData.icon.props, 'game/icons');

		flipX = isPlayer;

		antialiasing = SaveData.data.antialiasing;
	}
}

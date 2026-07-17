package game.objects.sprites;

import core.json.objects.CharacterData;

class Icon extends core.assets.FunkinSprite {
	public var bumpInBeats:Bool = true;
	public var stepTempo:Float = 1;

	public function new(isPlayer:Bool, ?characterData:CharacterData, ?sprite:String = 'face') {
		super();
		updateIcon(isPlayer, characterData, sprite);
	}

	public function updateIcon(isPlayer:Bool, characterData:CharacterData, ?sprite:String) {
		if (characterData != null && characterData.icon != null) {
			characterData.icon.props.position ??= [0, 0];
			bumpInBeats = characterData.icon.bumpInBeats ?? true;
			stepTempo = characterData.icon.stepTempo ?? 1;

			setPosition(characterData.icon.props.position[0], characterData.icon.props.position[1]);

			loadProps(characterData.icon.props, 'game/icons');
		} else {
			loadProps({name: 'default', path: sprite ?? 'face', position: [0.0, 0.0]}, 'game/icons');
			bumpInBeats = true;
			stepTempo = 1;
		}

		flipX = isPlayer;
		antialiasing = SaveData.data.antialiasing;
	}
}

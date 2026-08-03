package game.objects.sprites;

import core.json.objects.CharacterData;

class Icon extends modding.scripting.types.sprites.ScriptedSprite {
	public var bumpInBeats:Bool = true;
	public var stepTempo:Float = 2;

	public function new(isPlayer:Bool, ?characterData:CharacterData, ?sprite:String = 'face') {
		super();
		#if HSCRIPT_ALLOWED
		var iconScriptPath:String = (characterData != null && characterData.icon != null && characterData.icon.props != null) 
            ? characterData.icon.props.name 
            : (sprite ?? 'face');
		initScript('characters/icons/$characterData');
		#end
		updateIcon(isPlayer, characterData, sprite);
	}

	public function updateIcon(isPlayer:Bool, characterData:CharacterData, ?sprite:String) {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable('onCreateSprite', []))
			return;
		#end

		switch (characterData) {
			default:
                if (characterData != null && characterData.icon != null) {
                    var iconData = FormatJson.getIconDataPlaceholder(characterData.icon);

                    bumpInBeats = iconData.bumpInBeats;
                    stepTempo = iconData.stepTempo;

                    if (iconData.props != null) {
                        iconData.props.position ??= [0, 0];
                        setPosition(iconData.props.position[0], iconData.props.position[1]);
                        loadProps(iconData.props, 'game/icons');
                    } else {
                        loadProps({name: 'default', path: sprite ?? 'face', position: [0.0, 0.0]}, 'game/icons');
                    }
                } else {
                    var defaultData = FormatJson.getIconDataPlaceholder(null);

                    bumpInBeats = defaultData.bumpInBeats;
                    stepTempo = defaultData.stepTempo;

                    loadProps({name: 'default', path: sprite ?? 'face', position: [0.0, 0.0]}, 'game/icons');
                }

                flipX = isPlayer;
                antialiasing = SaveData.data.antialiasing;
		}

		#if HSCRIPT_ALLOWED
		script.call('postCreate', []);
		#end
	}
}

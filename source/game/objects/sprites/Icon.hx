package game.objects.sprites;

import core.json.objects.CharacterData;

class Icon extends modding.scripting.types.sprites.ScriptedSprite {
	public var bumpInBeats:Bool = true;
	public var baseScale:Float = 1;
	public var stepTempo:Float = 2;
	public var zIndex:Int = 0;
	public var bopEvery(get, set):Int;

	function get_bopEvery():Int
		return bumpInBeats ? Std.int(stepTempo * 4) : 0;

	function set_bopEvery(v:Int):Int {
		bumpInBeats = v > 0;
		if (v > 0)
			stepTempo = Math.max(1, v / 4);
		return v;
	}

	public function new(isPlayer:Bool, ?characterData:CharacterData, ?sprite:String = 'face') {
		super();
		#if HSCRIPT_ALLOWED
		var iconScriptPath:String = (characterData != null && characterData.icon != null && characterData.icon.props != null) ? characterData.icon.props.name : (sprite ?? 'face');
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
						if (frameWidth > 0) {
							if (iconData.size != null) {
								baseScale = iconData.size / frameWidth;
							} else if (iconData.props.scale != null && iconData.props.scale.length > 0) {
								baseScale = iconData.props.scale[0];
							} else {
								baseScale = 1.0;
							}
							scale.set(baseScale, baseScale);
							updateHitbox();
						}
					} else {
						loadProps(defaultProps(sprite), 'game/icons');
					}
				} else {
					var defaultData = FormatJson.getIconDataPlaceholder(null);

					bumpInBeats = defaultData.bumpInBeats;
					stepTempo = defaultData.stepTempo;

					loadProps(defaultProps(sprite), 'game/icons');
				}

				flipX = isPlayer != (characterData?.icon?.props?.flipX == true);
				antialiasing = SaveData.data.antialiasing;
		}

		#if HSCRIPT_ALLOWED
		script.call('postCreate', []);
		#end
	}

	static function defaultProps(sprite:String):core.json.extensions.SpriteData.ObjectData {
		return {
			name: 'default',
			path: sprite ?? 'face',
			position: [0.0, 0.0],
			firstAnim: 'normal',
			frameScale: [150, 150],
			anims: [
				{
					name: 'normal',
					indices: [0],
					looped: false,
					framerate: 24
				},
				{
					name: 'losing',
					indices: [1],
					looped: false,
					framerate: 24
				}
			]
		};
	}
}

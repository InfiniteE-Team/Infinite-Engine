package states.menus.objects;

import core.assets.FunkinSprite;
import core.json.menus.loading.LoadingCharacterData;

/**
 * The character sprite that appears in the loading screen.
 *
 * TODO: Consolidate this with `ModMenuCharacter`, and `CharSelectCharacter`!
 * They all share similar functionality which can be reduced.
 * - Abnormal
 */
// @:nullSafety
class FunkinLoadingCharacter extends FunkinSprite {
	/**
	 * The default animation this character plays.
	 */
	public static final DEFAULT_ANIMATION:String = 'idle';

	/**
	 * The default animation prefix this character uses.
	 */
	public static final DEFAULT_ANIMATION_PREFIX:String = 'run';

	var data:Null<LoadingCharacterData> = null;

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y, true);
	}

	/**
	 * Loads the specified character from a parsed data structure.
	 * @param newData The new character data to load.
	 * @param graphicPath The path to the character's graphic.
	 */
	public function loadCharacter(newData:LoadingCharacterData, graphicPath:flixel.graphics.frames.FlxFramesCollection):Void {
		data = newData;

		frames = graphicPath;
		scale.set(data.scale * 0.65, data.scale * 0.65);
		updateHitbox();
		this.setPosition(FlxG.width - (this.width - data.offsets[0]) - 200, FlxG.height - (this.height - data.offsets[1]) - 270);
		this.addAnim(DEFAULT_ANIMATION, DEFAULT_ANIMATION_PREFIX, 24);
		this.playAnim(DEFAULT_ANIMATION);
	}
}

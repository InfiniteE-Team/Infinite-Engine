package game.objects.sprites.notes;

import core.json.extensions.SpriteData.ObjectData;
import game.graphics.shaders.hardcode.RGBShader;
import core.json.objects.NoteSkinData;
import core.assets.FunkinSprite;

class StrumNote extends FunkinSprite {
	private var _rgbShader:flixel.addons.display.FlxRuntimeShader = null;

	public var noteSkin:String = 'default';

	var noteSkinData:NoteSkinData = null;

	public function new(x:Float, y:Float, props:ObjectData, noteSkin:String) {
		super();
		this.noteSkin = noteSkin;
		strumLoad(x, y, props);
	}

	public function strumLoad(x:Float, y:Float, noteSkinData:ObjectData) {
		setPosition(x, y);
		loadProps(noteSkinData, 'game/noteskins/$noteSkin/strumnotes');
	}

	public function applyShader(noteSkinData:NoteSkinData) {
		this.noteSkinData = noteSkinData;
		if (currentAnim != null && currentAnim != '')
			RGBShader.applyByAnimation(this, noteSkinData, currentAnim);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (noteSkinData == null)
			return;

		if (!currentAnim.startsWith('static')) {
			RGBShader.applyByAnimation(this, noteSkinData, currentAnim);
			_rgbShader = cast shader;
		} else {
			if (shader == _rgbShader)
				shader = null;
			_rgbShader = null;
		}
	}
}

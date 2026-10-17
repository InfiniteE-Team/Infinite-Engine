package game.objects.sprites.notes;

import core.json.extensions.SpriteData.ObjectData;
import game.graphics.shaders.hardcode.RGBShader;
import core.json.objects.NoteSkinData;
import core.assets.FunkinSprite;

class StrumNote extends FunkinSprite {
	private var _rgbShader:flixel.addons.display.FlxRuntimeShader = null;

	public var noteSkin:String = 'default';

	var noteSkinData:NoteSkinData = null;

	public var laneIndex:Int = 0;

	public var confirmHoldTimer:Float = -1;

	private var _confirmDuration:Float = 0.25;

	public function new(x:Float, y:Float, props:ObjectData, noteSkin:String) {
		super();
		this.noteSkin = noteSkin;
		loadSprite(x, y, props);
	}

	public function loadSprite(x:Float, y:Float, noteSkinData:ObjectData) {
		setPosition(x, y);
		loadProps(noteSkinData, 'game/noteskins/$noteSkin/strumnotes');
	}

	public function applyShader(noteSkinData:NoteSkinData) {
		this.noteSkinData = noteSkinData;
		if (currentAnim != null && currentAnim != '')
			RGBShader.applyByAnimation(this, noteSkinData, currentAnim);
	}

	public function startConfirm():Void {
		playAnim('confirm' + laneIndex, true);
		if (animation.curAnim != null && animation.curAnim.numFrames > 0) {
			var fps:Float = animation.curAnim.frameRate > 0 ? animation.curAnim.frameRate : 24.0;
			_confirmDuration = animation.curAnim.numFrames / fps;
		}
		confirmHoldTimer = 0.0;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (confirmHoldTimer >= 0) {
			confirmHoldTimer += elapsed;
			if (confirmHoldTimer >= _confirmDuration) {
				confirmHoldTimer = -1;
				playAnim('static' + laneIndex, true);
			}
		}

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

package game.objects.sprites.notes;

import core.json.game.objects.NoteSkinData;
import core.assets.FunkinSprite;
import core.rhythm.RhythmCore;
import core.render.shaders.hardcode.RGBShader;

class HoldSplash extends FunkinSprite {
	public var noteSkinData:NoteSkinData = null;
	public var noteType:String = 'normal';
	public var direction:Int = 0;
	public var noteSkin:String = 'default';

	public var keys:Int = 4;
	public var isEnding:Bool = false;

	public var strumline:Strumline;

	var _lastAnimForShader:String = '';

	public function new(keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0, ?noteType:String = 'normal') {
		super(x, y);
		setPosition(x, y);
		this.keys = keys;
		this.direction = direction;
		this.noteType = noteType;
		this.noteSkin = noteSkin;
		this.noteSkinData = noteSkinData;
		loadSprite(noteSkinData);
	}

	public function reinitHoldSplash(x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int, noteType:String = 'normal'):Void {
		setPosition(x, y);
		this.direction = direction;
		this.noteType = noteType;
		this.noteSkin = noteSkin;
		this.noteSkinData = noteSkinData;
		isEnding = false;
		_lastAnimForShader = '';
		loadSprite(noteSkinData);
	}

	public function loadSprite(noteSkinData:NoteSkinData) {
		isEnding = false;
		loadProps(noteSkinData.props, 'game/noteskins/$noteSkin/holdsplashes');
		playAnim('note$direction-startHold', true);
		RGBShader.applyByAnimation(this, noteSkinData, 'note$direction-startHold');
	}

	public function endHold():Void {
		if (isEnding)
			return;
		isEnding = true;
		if (strumline?.isPlayer)
			playAnim('note$direction-endHold', true);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (animation.curAnim != null) {
			if (currentAnim != null && currentAnim != '' && currentAnim != _lastAnimForShader) {
				RGBShader.applyByAnimation(this, noteSkinData, currentAnim);
				_lastAnimForShader = currentAnim;
			}

			if (animation.curAnim.finished) {
				if (animation.curAnim.name == 'note$direction-startHold') {
					playAnim('note$direction-loopHold', true);
				} else if (animation.curAnim.name == 'note$direction-endHold'
					|| (!strumline?.isPlayer && animation.curAnim.name == 'note$direction-loopHold')) {
					if (strumline != null)
						strumline.recycleHoldSplash(this);
					else
						kill();
				}
			}
		}
	}
}

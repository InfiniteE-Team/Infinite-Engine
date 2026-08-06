package game.objects.sprites.notes;

import core.json.objects.NoteSkinData;
import core.assets.FunkinSprite;
import core.rhythm.RhythmCore;
import game.graphics.shaders.hardcode.RGBShader;

class HoldSplash extends FunkinSprite {
	public var noteSkinData:NoteSkinData = null;
	public var noteType:String = 'normal';
	public var direction:Int = 0;
	public var noteSkin:String = 'default';

	public var keys:Int = 4;
	public var isEnding:Bool = false;

	public var noteControl:game.controllers.NoteController;

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
		playAnim('note$direction-endHold', true);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (currentAnim != null && currentAnim != '')
			RGBShader.applyByAnimation(this, noteSkinData, currentAnim);

		if (animation.curAnim != null && animation.curAnim.finished) {
			var animName:String = animation.curAnim.name;

			if (animName == 'note$direction-startHold') {
				playAnim('note$direction-loopHold', true);
			} else if (animName == 'note$direction-endHold') {
				if (noteControl != null)
					noteControl.recycleHoldSplash(this);
				else
					kill();
			}
		}
	}
}

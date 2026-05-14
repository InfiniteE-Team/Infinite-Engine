package game.objects.sprites.notes;

import core.json.extensions.SpriteData.ObjectData;
import core.assets.FunkinSprite;
import core.rhythm.RhythmCore;
import game.controllers.InputController;

class Note extends FunkinSprite {
	public var isSustain:Bool = false;
	public var noteType:String = 'normal';
	public var direction:Int = 0;
	public var noteSkin:String = 'default';

	// input good
	public var strumTime:Float = 0;
	public var wasGoodHit:Bool = false;
	public var canBeHit:Bool = false;
	public var mustPress:Bool = false;
	public var tooLate:Bool = false;

	public var keys:Int = 4;

	public var strum:StrumNote;

	var noteColors:Array<String> = ['purple', 'blue', 'green', 'red'];

	public function new(strumTime:Float, keys:Int, x:Float, y:Float, isSustain:Bool, noteSkinData:ObjectData, noteSkin:String, direction:Int = 0,
			?noteType:String = 'normal') {
		super(x, y);

		setPosition(x, y);
		this.keys = keys;
		this.direction = direction;
		this.strumTime = strumTime;
		this.isSustain = isSustain;
		this.noteType = noteType;
		this.noteSkin = noteSkin;
		noteLoad(noteSkinData);
	}

	public function noteLoad(noteSkinData:ObjectData) {
		loadProps(noteSkinData, 'noteskins/$noteSkin');
		for (i in 0...keys)
			playAnim(noteColors[i]+"Scroll",true);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!mustPress) {
			canBeHit = false;
			if (strumTime <= RhythmCore.songPosition)
				wasGoodHit = true;
		} else if (mustPress && !wasGoodHit && !tooLate) {
			canBeHit = (RhythmCore.songPosition >= strumTime - InputController.SHIT_WINDOW
				&& RhythmCore.songPosition <= strumTime + InputController.SHIT_WINDOW);

			if (RhythmCore.songPosition > strumTime + InputController.SHIT_WINDOW)
				tooLate = true;
		}
	}

	public function config() {
		if (isSustain) {} else {}
	}
}

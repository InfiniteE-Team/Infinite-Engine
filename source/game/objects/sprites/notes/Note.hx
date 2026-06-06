package game.objects.sprites.notes;

import core.json.extensions.SpriteData.ObjectData;
import core.assets.FunkinSprite;
import core.rhythm.RhythmCore;
import game.controllers.NoteController;
import game.graphics.shaders.hardcode.RGBShader;
import core.json.objects.NoteSkinData;

class Note extends FunkinSprite {
	public var noteType:String = 'normal';
	public var direction:Int = 0;
	public var noteSkin:String = 'default';

	// input good
	public var strumTime:Float = 0;
	public var wasGoodHit:Bool = false;
	public var canBeHit:Bool = false;
	public var mustPress:Bool = false;
	public var tooLate:Bool = false;

	public var rating:String = 'sick';

	public var keys:Int = 4;

	public var strum:StrumNote;

	public var noteControl:NoteController;

	public function new(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0,
			?noteType:String = 'normal') {
		super(x, y);

		setPosition(x, y);
		this.keys = keys;
		this.direction = direction;
		this.strumTime = strumTime;
		this.noteType = noteType;
		this.noteSkin = noteSkin;
		noteLoad(noteSkinData);
	}

	public function noteLoad(noteSkinData:NoteSkinData) {
		loadProps(noteSkinData.props, 'game/noteskins/$noteSkin/strumnotes');
		playAnim('note$direction-Scroll', true);
		RGBShader.applyFromSkin(this, noteSkinData, direction);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!mustPress) {
			canBeHit = false;
			if (strumTime <= RhythmCore.songPosition)
				wasGoodHit = true;
		} else if (mustPress && !wasGoodHit && !tooLate) {
			canBeHit = (RhythmCore.songPosition >= strumTime - noteControl.getWorstWindow()
				&& RhythmCore.songPosition <= strumTime + noteControl.getWorstWindow());

			if (RhythmCore.songPosition > strumTime + noteControl.getWorstWindow())
				tooLate = true;
		}
	}
}
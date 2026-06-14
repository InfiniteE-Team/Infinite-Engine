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

	private var noteSkinData:NoteSkinData = null;
	private var _lastAnimationName:String = '';

	public var wasMissed:Bool = false;

	public function new(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0,
			?noteType:String = 'normal') {
		super(x, y);

		setPosition(x, y);
		this.keys = keys;
		this.direction = direction;
		this.strumTime = strumTime;
		this.noteType = noteType;
		this.noteSkin = noteSkin;
		this.noteSkinData = noteSkinData;
		noteLoad(noteSkinData);
	}

	public function reinit(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0,
			?noteType:String = 'normal') {
		setPosition(x, y);
		this.keys = keys;
		this.direction = direction;
		this.strumTime = strumTime;
		this.noteType = noteType ?? 'normal';
		this.noteSkin = noteSkin;
		this.noteSkinData = noteSkinData;

		// reset estado
		wasGoodHit = false;
		canBeHit = false;
		mustPress = false;
		tooLate = false;
		wasMissed = false;
		rating = 'sick';
		strum = null;
		noteControl = null;
		_lastAnimationName = '';
		alpha = 1;
		visible = true;

		playAnim('note$direction-Scroll', true);
		RGBShader.applyByAnimation(this, noteSkinData, 'note$direction-Scroll');
	}

	public function noteLoad(noteSkinData:NoteSkinData) {
		loadProps(noteSkinData.props, 'game/noteskins/$noteSkin/strumnotes');
		playAnim('note$direction-Scroll', true);
		RGBShader.applyByAnimation(this, noteSkinData, 'note$direction-Scroll');
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (animation.name != null && animation.name != _lastAnimationName) {
			_lastAnimationName = animation.name;
			if (noteSkinData != null && noteSkinData.colorPalette != null) {
				RGBShader.applyByAnimation(this, noteSkinData, _lastAnimationName);
			}
		}

		if (!mustPress) {
			canBeHit = false;
			if (strumTime <= RhythmCore.songPosition)
				wasGoodHit = true;
		} else if (mustPress && !wasGoodHit && !tooLate && !wasMissed) {
			canBeHit = (RhythmCore.songPosition >= strumTime - noteControl.worstWindow
				&& RhythmCore.songPosition <= strumTime + noteControl.worstWindow);

			if (RhythmCore.songPosition > strumTime + noteControl.worstWindow)
				tooLate = true;
		}
	}
}

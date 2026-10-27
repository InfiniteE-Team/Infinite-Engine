package game.objects.sprites.notes;

import core.json.extensions.SpriteData.ObjectData;
import core.assets.FunkinSprite;
import core.rhythm.RhythmCore;
import game.controllers.NoteController;
import core.render.shaders.hardcode.RGBShader;
import core.json.objects.NoteSkinData;

class Note extends FunkinSprite {
	public var noteType:String = 'normal';
	public var direction:Int = 0;
	public var noteSkin:String = 'default';

	public var strumTime:Float = 0;
	public var wasGoodHit:Bool = false;
	public var canBeHit:Bool = false;
	public var mustPress:Bool = false;
	public var tooLate:Bool = false;

	public var rating:String = 'sick';
	public var keys:Int = 4;
	public var strum:StrumNote;
	public var noteControl:NoteController;

	public var strumline:Strumline;

	public var localLane:Int = 0;

	// Scrollspeed cache
	public var scrollMult:Float = 0.0;

	public var noteDownscroll:Bool = false;

	private var noteSkinData:NoteSkinData = null;

	public var wasMissed:Bool = false;
	public var missAnimPlayed:Bool = false;

	var _lastAnimForShader:String = '';

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
		loadSprite(noteSkinData);
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

		wasGoodHit = false;
		canBeHit = false;
		mustPress = false;
		tooLate = false;
		wasMissed = false;
		missAnimPlayed = false;
		rating = 'sick';
		strum = null;
		noteControl = null;
		strumline = null;
		localLane = 0;
		scrollMult = 0.0;
		noteDownscroll = false;
		alpha = 1;
		visible = true;

		playAnim('note$direction-Scroll', true);
		RGBShader.applyByAnimation(this, noteSkinData, 'note$direction-Scroll');
	}

	public function loadSprite(noteSkinData:NoteSkinData) {
		var basePath = noteType != null
			&& noteType != 'normal' ? 'game/notetypes/$noteType/strumnotes' : 'game/noteskins/$noteSkin/strumnotes';
		loadProps(noteSkinData.props, basePath);
		playAnim('note$direction-Scroll', true);
		RGBShader.applyByAnimation(this, noteSkinData, 'note$direction-Scroll');
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (currentAnim != null && currentAnim != '' && currentAnim != _lastAnimForShader) {
			RGBShader.applyByAnimation(this, noteSkinData, currentAnim);
			_lastAnimForShader = currentAnim;
		}

		if (wasMissed) {
			alpha = 0.6;
			mustPress = false;
		}

		if (!mustPress) {
			canBeHit = false;
			if (strumTime <= RhythmCore.songPosition)
				wasGoodHit = true;
		} else if (!wasGoodHit && !tooLate && !wasMissed) {
			var ww = noteControl.worstWindow;
			var sp = RhythmCore.songPosition;
			canBeHit = (sp >= strumTime - ww && sp <= strumTime + ww);
			if (sp > strumTime + ww)
				tooLate = true;
		}
	}
}

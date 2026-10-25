package game.objects.sprites.notes;

import core.assets.FunkinSprite;
import core.json.extensions.SpriteData.ObjectData;
import core.render.shaders.hardcode.RGBShader;
import core.json.objects.NoteSkinData;

class NoteSustain extends Note {
	public var length:Float = 0;

	public var isHeld:Bool = false;

	public var parentNote:NoteSustain = null;

	public var wasNoteHit:Bool = false;

	public var isSustainEnd:Bool = false;

	var baseScaleX:Float = 1.0;
	var baseScaleY:Float = 1.0;

	public function new(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0, length:Float,
			?noteType:String = 'normal', isSustainEnd:Bool = false) {
		this.length = length;
		this.isSustainEnd = isSustainEnd;
		super(strumTime, keys, x, y, noteSkinData, noteSkin, direction, noteType);
		baseScaleX = scale.x;
		baseScaleY = scale.y;
	}

	override public function reinit(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0,
			?noteType:String = 'normal') {
		setPosition(x, y);
		this.keys = keys;
		this.direction = direction;
		this.strumTime = strumTime;
		this.noteType = noteType ?? 'normal';
		this.noteSkin = noteSkin;
		@:privateAccess this.noteSkinData = noteSkinData;
		wasGoodHit = false;
		canBeHit = false;
		mustPress = false;
		tooLate = false;
		wasMissed = false;
		missAnimPlayed = false;
		rating = 'sick';
		strum = null;
		noteControl = null;
		alpha = 1;
		visible = true;
	}

	public function reinitSustain(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0, length:Float,
			?noteType:String = 'normal', isSustainEnd:Bool = false) {
		var prevSkin = this.noteSkin;
		var prevType = this.noteType;
		this.length = length;
		this.isSustainEnd = isSustainEnd;
		this.isHeld = false;
		this.wasNoteHit = false;
		this.parentNote = null;
		this.clipRect = null;

		scale.set(baseScaleX, baseScaleY);

		reinit(strumTime, keys, x, y, noteSkinData, noteSkin, direction, noteType);

		var animName = isSustainEnd ? 'note$direction-HoldEnd' : 'note$direction-Hold';

		if (noteSkin != prevSkin || (noteType ?? 'normal') != (prevType ?? 'normal'))
			loadSprite(noteSkinData);
		else {
			playAnim(animName, true);
			RGBShader.applyByAnimation(this, noteSkinData, animName);
		}
	}

	override function loadSprite(noteSkinData:NoteSkinData) {
		loadProps(noteSkinData.props, 'game/noteskins/$noteSkin/strumnotes');
		var animName = isSustainEnd ? 'note$direction-HoldEnd' : 'note$direction-Hold';
		playAnim(animName);
		RGBShader.applyByAnimation(this, noteSkinData, animName);

		baseScaleX = scale.x;
		baseScaleY = scale.y;
	}
}

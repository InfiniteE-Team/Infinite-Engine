package game.objects.sprites.notes;

import core.json.objects.NoteSkinData;
import core.assets.FunkinSprite;
import core.rhythm.RhythmCore;
import game.graphics.shaders.hardcode.RGBShader;

class NoteSplash extends FunkinSprite {
	public var noteSkinData:NoteSkinData = null;
	public var noteType:String = 'normal';
	public var direction:Int = 0;
	public var noteSkin:String = 'default';

	public var random:Float = 0;

	public var keys:Int = 4;

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
		loadProps(noteSkinData.props, 'game/noteskins/$noteSkin/splashes');
		playAnim('note$direction-Splash$random', true);
		RGBShader.applyByAnimation(this, noteSkinData, 'note$direction-Scroll');
	}

	override public function playAnim(name:Null<String>, ?force:Bool = true) {
		super.playAnim(name, force);

		if (isFinished('splash'))
			kill();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (currentAnim != null && currentAnim != '')
			RGBShader.applyByAnimation(this, noteSkinData, currentAnim);
	}
}

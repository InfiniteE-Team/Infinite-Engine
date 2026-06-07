package game.objects.sprites.notes;

import core.json.extensions.SpriteData.ObjectData;
import core.assets.FunkinSprite;
import core.rhythm.RhythmCore;

class NoteSplash extends FunkinSprite {
	public var noteType:String = 'normal';
	public var direction:Int = 0;
	public var noteSkin:String = 'default';

	public var random:Float = 0;

	public var keys:Int = 4;

	public function new(keys:Int, x:Float, y:Float, noteSkinData:ObjectData, noteSkin:String, direction:Int = 0, ?noteType:String = 'normal') {
		super(x, y);

		setPosition(x, y);
		this.keys = keys;
		this.direction = direction;
		this.noteType = noteType;
		this.noteSkin = noteSkin;
		noteLoad(noteSkinData);
	}

	public function noteLoad(noteSkinData:ObjectData) {
		loadProps(noteSkinData, 'game/noteskins/$noteSkin/splashes');
		playAnim('note$direction-Splash$random', true);
	}

	override public function playAnim(name:Null<String>, ?force:Bool = true)
	{
		super.playAnim(name,force);

		if (isFinished('splash'))
			kill();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}
}

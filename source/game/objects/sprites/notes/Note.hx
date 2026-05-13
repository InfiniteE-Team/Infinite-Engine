package game.objects.sprites.notes;
import core.json.extensions.SpriteData.ObjectData;
import core.assets.FunkinSprite;

class Note extends FunkinSprite {
	public var isSustain:Bool = false;
	public var noteType:String = 'normal';
    public var direction:Int = 0;
    public var noteSkin:String = 'default';

	public function new(x:Float, y:Float, isSustain:Bool,noteSkinData:ObjectData,noteSkin:String,direction:Int = 0,?noteType:String = 'normal') {
		super(x, y);

		setPosition(x, y);
        this.direction = direction;
		this.isSustain = isSustain;
        this.noteType = noteType;
        this.noteSkin = noteSkin;
		noteLoad(noteSkinData);
	}

    public function noteLoad(noteSkinData:ObjectData) {
		loadProps(noteSkinData, 'noteskins/$noteSkin');
	}

	public function config() {
		if (isSustain) {} else {}
	}
}
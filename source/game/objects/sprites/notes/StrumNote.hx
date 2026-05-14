package game.objects.sprites.notes;
import core.json.extensions.SpriteData.ObjectData;
import core.assets.FunkinSprite;

class StrumNote extends FunkinSprite {
	public var noteSkin:String = 'default';
	public function new(x:Float, y:Float, props:ObjectData, noteSkin:String) {
		super();
		this.noteSkin = noteSkin;
        strumLoad(x,y,props);
	}

	public function strumLoad(x:Float,y:Float,noteSkinData:ObjectData) {
		setPosition(x, y);
		loadProps(noteSkinData, 'noteskins/$noteSkin');
	}
}
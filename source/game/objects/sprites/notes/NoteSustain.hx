package game.objects.sprites.notes;
import core.assets.FunkinSprite;
import core.json.extensions.SpriteData.ObjectData;

class NoteSustain extends Note {
	public var length:Float = 0;
	public var endSprite:FunkinSprite;

	public var isHeld:Bool = false;

	public function new(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:ObjectData, noteSkin:String, direction:Int = 0, length:Float,
			?noteType:String = 'normal') {
		this.length = length;
		super(strumTime, keys, x, y, noteSkinData, noteSkin, direction, noteType);
	}

	override function noteLoad(noteSkinData:ObjectData) {
		loadProps(noteSkinData, 'noteskins/$noteSkin/strumnotes');
		playAnim('note$direction-Hold');
		endSprite = new FunkinSprite(x, y);
		endSprite.loadProps(noteSkinData, 'noteskins/$noteSkin/strumnotes');
		endSprite.playAnim('note$direction-HoldEnd');
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (endSprite != null) {
			endSprite.x = x;
			endSprite.y = y + height - endSprite.height;
		}
	}

	override function draw() {
		super.draw();
		if (endSprite != null)
			endSprite.draw();
	}
}

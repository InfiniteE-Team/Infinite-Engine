package game.objects.sprites.notes;

import core.json.extensions.SpriteData.ObjectData;
import core.assets.FunkinSprite;

class StrumNote extends FunkinSprite {
	public var noteSkin:String = 'default';

	public function new(x:Float, y:Float, props:ObjectData, noteSkin:String) {
		super();
		this.noteSkin = noteSkin;
		strumLoad(x, y, props);
	}

	public function strumLoad(x:Float, y:Float, noteSkinData:ObjectData) {
		setPosition(x, y);
		loadProps(noteSkinData, 'noteskins/$noteSkin');

		var counts:Map<String, Int> = new Map();
		for (anim in noteSkinData.anims) {
			var c = counts.exists(anim.name) ? counts.get(anim.name) : 0;
			if (c == ID)
				animation.addByPrefix(anim.name, anim.prefix, anim.framerate, anim.looped);
			counts.set(anim.name, c + 1);
		}
	}
}

package game.objects.sprites.notes;

import core.assets.FunkinSprite;
import core.json.extensions.SpriteData.ObjectData;
import game.graphics.shaders.hardcode.RGBShader;
import core.json.objects.NoteSkinData;

class NoteSustain extends Note {
	public var length:Float = 0;

	public var isHeld:Bool = false;

	public var isSustainEnd:Bool = false;

	public var parentNote:NoteSustain = null;

	public function new(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0, length:Float,
			?noteType:String = 'normal', isSustainEnd:Bool = false) {
		this.length = length;
		this.isSustainEnd = isSustainEnd;
		super(strumTime, keys, x, y, noteSkinData, noteSkin, direction, noteType);
	}

	override function noteLoad(noteSkinData:NoteSkinData) {
		loadProps(noteSkinData.props, 'game/noteskins/$noteSkin/strumnotes');
		if (isSustainEnd) {
			playAnim('note$direction-HoldEnd');
		} else {
			playAnim('note$direction-Hold');
		}
		RGBShader.applyFromSkin(this, noteSkinData, direction);
	}
}

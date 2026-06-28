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

	public var mesh:game.modchart.SustainMesh = null;

	public function new(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0, length:Float,
			?noteType:String = 'normal', isSustainEnd:Bool = false) {
		this.length = length;
		this.isSustainEnd = isSustainEnd;
		super(strumTime, keys, x, y, noteSkinData, noteSkin, direction, noteType);
	}

	public function reinitSustain(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0, length:Float,
			?noteType:String = 'normal', isSustainEnd:Bool = false) {
		this.length = length;
		this.isSustainEnd = isSustainEnd;
		this.isHeld = false;
		this.parentNote = null;

		if (mesh != null) {
			mesh.destroy();
			mesh = null;
		}
		
		clipRect = null;

		reinit(strumTime, keys, x, y, noteSkinData, noteSkin, direction, noteType);

		var animName = isSustainEnd ? 'note$direction-HoldEnd' : 'note$direction-Hold';
		playAnim(animName, true);
		RGBShader.applyByAnimation(this, noteSkinData, animName);
	}

	override function loadSprite(noteSkinData:NoteSkinData) {
		loadProps(noteSkinData.props, 'game/noteskins/$noteSkin/strumnotes');
		var animName = isSustainEnd ? 'note$direction-HoldEnd' : 'note$direction-Hold';
		playAnim(animName);
		RGBShader.applyByAnimation(this, noteSkinData, animName);
	}
}

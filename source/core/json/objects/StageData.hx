package core.json.objects;
import core.json.extensions.AudioData;
import core.json.extensions.SpriteData.ObjectData;
import core.enums.ElementType;

typedef StageData = {
	var name:String;
	var defaultZoom:Float;
	var elements:Array<StageElement>;
	var ?hideGF:Bool;
}

typedef StageElement = {
	var type:ElementType;
	var ?props:ObjectData;
	var ?audio:AudioData;
	var ?repeatX:Bool;
	var ?repeatY:Bool;
	var ?velocityX:Float;
	var ?velocityY:Float;

	// chars
	var ?id:String;
	var ?position:Array<Float>;
	var ?camPos:Array<Float>;
}

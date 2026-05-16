package core.json.objects;
import core.json.extensions.AudioData;
import core.json.extensions.SpriteData.ObjectData;
import core.json.song.SongData.CharDataJson;
import core.json.extensions.AudioData;

typedef StageData =
{
	var name:String;
	var defaultZoom:Float;
	var elements:Array<StageElement>;
	var ?hideGF:Bool;
}

typedef StageElement =
{
	var type:Dynamic; // "sprite", "animated", "graphic", "group", "sound", "custom_class", "custom_class_group", "character"
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
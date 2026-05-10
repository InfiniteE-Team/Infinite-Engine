package core.json.objects;
import core.json.extensions.AudioData;
import core.json.extensions.SpriteData;
import core.json.song.SongData.CharDataJson;

typedef StageData =
{
	var name:String;
	var defaultZoom:Float;
    var ?charsProps:Array<CharDataJson>;
	var elements:Array<StageElement>;
	var ?hideGF:Bool;
}

typedef StageElement =
{
	var type:Dynamic; // "sprite", "animated", "graphic", "group", "sound", "custom_class", "custom_class_group", "character"
    var props:SpriteData.ObjectData;
	var ?repeatX:Bool;
	var ?repeatY:Bool;
	var ?velocityX:Float;
	var ?velocityY:Float;
}
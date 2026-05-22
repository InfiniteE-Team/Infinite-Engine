package core.json.engine;
import core.json.extensions.AudioData;
import core.json.extensions.SpriteData.ObjectData;

typedef MenuData = {
    var elements:Array<Element>;
}

typedef Element =
{
	var type:Dynamic; // "sprite", "animated", "graphic", "group", "sound", "custom_class", "custom_class_group", "character"
    var ?props:ObjectData;
	var ?audio:AudioData;
	var ?repeatX:Bool;
	var ?repeatY:Bool;
	var ?velocityX:Float;
	var ?velocityY:Float;
}
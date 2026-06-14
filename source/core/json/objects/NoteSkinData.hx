package core.json.objects;
import core.json.extensions.SpriteData;

typedef NoteSkinData = {
	var props:ObjectData;
	var ?author:String;
	var ?description:String;
	var ?colorPalette:haxe.DynamicAccess<Array<String>>;
	var ?spacing:Float;
	var ?keys:Int;
}
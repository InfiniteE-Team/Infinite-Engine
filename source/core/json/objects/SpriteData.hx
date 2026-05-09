package core.json.objects;

import haxe.extern.EitherType;

// Data for sprites objects
typedef ObjectData = {
	var name:String;
	var path:String;
	var ?position:Array<Float>;

	var ?scale:Array<Float>;
	var ?alpha:Float;
	var ?visible:Bool;

	var ?flipX:Bool;
	var ?flipY:Bool;

	var ?antialiasing:Bool;
	var anims:Array<AnimData>;
}

// Data for anims
typedef AnimData = {
	var ?offsets:Array<Float>;
	var name:String;

	var ?filePath:EitherType<String, Array<String>>;

	var ?looped:Bool;
	var ?framerate:Float;

	var prefix:String;

	var ?indices:Array<Int>;

	var ?flipX:Bool;

    var ?flipY:Bool;
}
package core.json.extensions;

import haxe.extern.EitherType;

// Data for sprites objects
typedef ObjectData = {
	var name:String;
	var ?path:String;
	var ?position:Array<Float>;

	var ?scale:Array<Float>;
	var ?alpha:Float;
	var ?visible:Bool;

	var ?flipX:Bool;
	var ?flipY:Bool;

	var ?angle:Float;

	var ?active:Bool;

	var ?scrollFactor:Array<Float>;

	var ?color:String;

	var ?antialiasing:Bool;

	var ?blend:String;
	
    var ?frameScale:Array<Int>;

	var ?anims:Array<AnimData>;
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
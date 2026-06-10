package core.json.engine;

typedef SaveDataFields = {
    var ?framerate:Int;
	var ?antialiasing:Bool;

	var ?downscroll:Bool;
	var ?middlescroll:Bool;
    var ?ghosttaping:Bool;

	var ?noteKeyPresets:haxe.DynamicAccess<Array<Array<String>>>;
	var ?uiKeys:Array<Array<String>>;
}
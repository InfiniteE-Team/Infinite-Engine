package core.json.engine;

typedef SaveDataFields = {
	// graphics
    var ?framerate:Int;
	var ?fpsVisible:Bool;
	var ?antialiasing:Bool;
	var ?shaders:Bool;

	// gameplay
	var ?downscroll:Bool;
	var ?middlescroll:Bool;
    var ?ghosttaping:Bool;
	
	// controls
	var ?noteKeyPresets:haxe.DynamicAccess<Array<Array<String>>>;
	var ?uiKeys:Array<Array<String>>;

	// debug
	var logInScreen:Null<Bool>;

	// mods
	var onMod:Null<Bool>;
	var currentMod:Null<String>;
}
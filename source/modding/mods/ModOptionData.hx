package modding.mods;

typedef ModOptionEntry = {
	var name:String;
	var description:String;
	var saveField:String;
	var type:String; // "CHECKBOX" or "NUMBER"
	var ?min:Float;
	var ?max:Float;
	var ?step:Float;
	var ?displayFormat:String;
}

typedef ModKeybindEntry = {
	var groupName:String;
	var label:String;
	var actions:Array<String>;
}

typedef ModOptionsFile = {
	var ?categories:Array<ModOptionCategory>;
	var ?keybinds:Array<ModKeybindEntry>;
}

typedef ModOptionCategory = {
	var name:String;
	var options:Array<ModOptionEntry>;
}

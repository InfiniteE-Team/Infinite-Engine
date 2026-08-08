package modding.mods;

typedef ModData = {
	var ?nameMod:String;
	var ?author:String;
	var ?appIcon:String;
	var ?description:String;
	var ?startingMod:Bool;

	// APIs
	var ?discord:String;
	var ?webPage:String;
}

class ModConfig {
	public function new() {}

	public static function init() {}
}

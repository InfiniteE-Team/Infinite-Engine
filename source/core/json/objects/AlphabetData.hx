package core.json.objects;

import core.enums.AlphabetStyle;

typedef AlphabetData = {
	var text:String;

	var ?style:AlphabetStyle; // default: Bold

	var ?x:Float;
	var ?y:Float;

	var ?scale:Float;

	var ?separation:Float;

	var ?alpha:Float; // default: 1.0

	// color tint (hex string "#RRGGBB")
	var ?color:String;

	var ?centered:Bool;

	var ?isMenuItem:Bool;

	var ?letterDelay:Float;
}

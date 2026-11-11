package core.json.game.objects;

typedef RatingData = {
	var ratings:Array<RatingDataType>;
}

typedef RatingDataType = {
	var name:String;
	var path:String;
	var score:Int;

	var health:Float;
	var ?window:Float;
	var ?miss:Bool;

	var ?splash:Bool;
}

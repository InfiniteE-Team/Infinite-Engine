package core.json.song;

typedef RatingData = {
    var ratings:Array<RatingDataType>;
}

typedef RatingDataType = {
    var rating:String;
    var path:String;
    var score:Int;
    var accuracyWeight:Float;
    
    var health:Float;
    var ?window:Float;
    var ?miss:Bool;
}
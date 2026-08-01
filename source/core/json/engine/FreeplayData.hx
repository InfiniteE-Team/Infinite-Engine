package core.json.engine;

typedef FreeplayData = {
    var songData:Array<SongData>;
}

typedef SongData = {
    var song:String;
    var ?icon:String;
    var ?bpm:Float;
    var ?artist:String;
    var ?album:String;
}
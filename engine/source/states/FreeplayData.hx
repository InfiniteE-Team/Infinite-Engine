typedef FreeplayData = {
    var songData:Array<SongData>;
}

typedef SongData = {
    var song:String;
    var bpm:Float;
    var ?artist:String;
}
package core.json.song;

typedef SongData =
{
    var gameplay:GameplayData;
    var notes:Array<NoteData>;
}

typedef GameplayData =
{
    var chars:Array<CharDataJson>;
    var events:Array<EventsData>;
}

typedef CharDataJson =
{
    var id:String;
    var name:String;
    var type:String;
}

typedef EventsData =
{
    var id:String;
    var time:Float;
    var name:String;
}

// nose
typedef NoteData =
{
    var nose:String;
}
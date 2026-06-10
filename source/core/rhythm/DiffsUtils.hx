package core.rhythm;

import sys.FileSystem;

class DiffsUtils
{
    public static var difficulties:Array<String> = [];

    public function new() {
        difficulties = [];
        var diffsDir = Paths.findLib('songs/${PlayState.SONG.songName.toLowerCase()}/charts/');

        if (FileSystem.exists(diffsDir)) {
            for (file in sys.FileSystem.readDirectory(diffsDir)) {
                
			}
        }

        if (difficulties.length == 0) {
            difficulties.push("");
        }
    }

    public static function getDiffIndex(diff:String):Int
    {
        return difficulties.indexOf(diff);
    }
}
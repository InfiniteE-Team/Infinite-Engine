package core.assets;
import flixel.graphics.frames.FlxAtlasFrames;
import sys.FileSystem;

class Paths
{
    static final libs = ["engine","assets"];

    public static function getPath(fileName:String, ?type:String = "default"):Dynamic
    {
        switch (type)
        {
            case "json":
                return findLib("data/" + fileName+'.json');
            case "image":
                return findLib("images/"+fileName+'.png');
            case "sound":
                return findLib("sounds/"+fileName+'.ogg');
            case "music":
                return findLib("music/"+fileName+'.ogg');
            case "animated":
                return FlxAtlasFrames.fromSparrow(getPath(fileName, "image"), getPath("images/" + fileName, "xml"));
            case "xml":
                return findLib(fileName+'.xml');
            default:
                return findLib(fileName);
        }
    }

    static function findLib(file:String):String {
        for (lib in libs)
            if (FileSystem.exists('$lib/$file'))
                return '$lib/$file';

        trace('Paths: "$file" not found.');
        return '${libs[0]}/$file';
    }

    public static function listFolder(folder:String):Array<String> {
        var result = [];
        for (lib in libs)
            if (FileSystem.exists('$lib/$folder'))
                for (name in FileSystem.readDirectory('$lib/$folder'))
                    if (!result.contains(name))
                        result.push(name);
        return result;
    }
}
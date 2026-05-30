package game.graphics.shaders.hardcode;

import flixel.addons.display.FlxRuntimeShader;
import core.json.objects.NoteSkinData;

class RGBShader {
    static var _src:String = null;

    static function getSrc():String {
        if (_src == null) {
            var path = Paths.getPath('rgbFix', 'shaders');
            if (sys.FileSystem.exists(path))
                _src = sys.io.File.getContent(path);
            else
                trace('Not found shader source: $path');
        }
        return _src;
    }

    public static function applyColor(sprite:flixel.FlxSprite, color:NoteColor, mult:Float = 1.0) {
        if (color == null) return;
        var src = getSrc();
        if (src == null) return;

        var sh = new FlxRuntimeShader(src);
        sh.data.r.value = color.r;
        sh.data.g.value = color.g;
        sh.data.b.value = color.b;
        sh.data.mult.value = [mult];
        sh.data.blocksize.value = [1.0, 1.0];
        sprite.shader = sh;
    }

    public static function applyFromSkin(sprite:flixel.FlxSprite, noteSkinData:NoteSkinData, direction:Int) {
        if (noteSkinData?.colorPalette == null) return;
        var idx = direction % noteSkinData.colorPalette.length;
        applyColor(sprite, noteSkinData.colorPalette[idx]);
    }
}
package core.render;

import flixel.FlxCamera;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.OpenGLRenderer;
import openfl.display3D.textures.TextureBase;

@:nullSafety
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display.OpenGLRenderer)
@:access(flixel.FlxCamera)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.Sprite)
class FixedBitmapData extends openfl.display.BitmapData {
    override function __drawGL(source:IBitmapDrawable, renderer:OpenGLRenderer):Void {
        if (Std.isOfType(source, DisplayObject)) {
            final object:DisplayObjectContainer = cast source;
            renderer.__stage = object.stage;
        }
        super.__drawGL(source, renderer);
    }

    public static function create(width:Int, height:Int, useGPU:Bool = true):FixedBitmapData {
        if (useGPU) {
            var texture:TextureBase = _createTexture(width, height);
            return fromTexture(texture);
        }
        return new FixedBitmapData(width, height, true, 0);
    }

    public static function fromTexture(texture:TextureBase):FixedBitmapData {
        var bitmapData:FixedBitmapData = new FixedBitmapData(texture.__width, texture.__height, true, 0);
        bitmapData.readable = false;
        bitmapData.__texture = texture;
        bitmapData.__textureContext = texture.__textureContext;
        @:nullSafety(Off)
        bitmapData.image = null;
        return bitmapData;
    }

    static function _createTexture(width:Int, height:Int):TextureBase {
        width  = width  < 1 ? 1 : width;
        height = height < 1 ? 1 : height;
        return openfl.Lib.current.stage.context3D.createTexture(width, height, BGRA, true);
    }
}
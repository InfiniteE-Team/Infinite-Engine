package core.render;

import openfl.display.BitmapData;
import openfl.display.OpenGLRenderer;
import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;

@:nullSafety
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.OpenGLRenderer)
@:access(flixel.FlxCamera)
@:access(openfl.display.Sprite)
@:access(openfl.geom.ColorTransform)
class BitmapDataUtil {
	static var renderer(get, never):OpenGLRenderer;
	static var _renderer:Null<OpenGLRenderer>;

	static inline function get_renderer():OpenGLRenderer {
		if (_renderer == null) {
			_renderer = new OpenGLRenderer(FlxG.stage.context3D);
			_renderer.__worldTransform = new openfl.geom.Matrix();
			_renderer.__worldColorTransform = new openfl.geom.ColorTransform();
		}
		return _renderer;
	}

	public static function drawCameraScreen(bitmap:BitmapData, camera:flixel.FlxCamera, clearBitmap:Bool = true, drawFlashSprite:Bool = false):BitmapData {
		var matrix:flixel.math.FlxMatrix = new flixel.math.FlxMatrix();
		var pivotX:Float = FlxG.scaleMode.scale.x;
		var pivotY:Float = FlxG.scaleMode.scale.y;

		matrix.setTo(1 / pivotX, 0, 0, 1 / pivotY, camera.flashSprite.x / pivotX, camera.flashSprite.y / pivotY);

		if (clearBitmap)
			bitmap.__fillRect(bitmap.rect, 0, true);

		camera.render();
		camera.flashSprite.__update(false, true);

		renderer.__cleanup();
		renderer.setShader(renderer.__defaultShader);
		renderer.__allowSmoothing = false;
		renderer.__pixelRatio = openfl.Lib.current.stage.window.scale;
		renderer.__worldAlpha = 1 / camera.flashSprite.__worldAlpha;
		renderer.__worldTransform.copyFrom(camera.flashSprite.__renderTransform);
		renderer.__worldTransform.invert();
		renderer.__worldTransform.concat(matrix);
		renderer.__worldColorTransform.__copyFrom(camera.flashSprite.__worldColorTransform);
		renderer.__worldColorTransform.__invert();
		renderer.__setRenderTarget(bitmap);

		if (drawFlashSprite)
			bitmap.__drawGL(camera.flashSprite, renderer);
		else
			bitmap.__drawGL(camera.canvas, renderer);

		return bitmap;
	}

	public static function resize(bitmap:BitmapData, width:Int, height:Int):Void {
		if (bitmap.width == width && bitmap.height == height)
			return;
		bitmap.width = width;
		bitmap.height = height;
		if (!bitmap.readable)
			resizeTexture(bitmap.__texture, width, height);
	}

	public static function resizeTexture(texture:TextureBase, width:Int, height:Int):Void {
		if (texture.__width == width && texture.__height == height)
			return;
		var context:Context3D = texture.__context;
		texture.__width = width;
		texture.__height = height;
		context.__bindGLTexture2D(texture.__textureID);
		context.gl.texImage2D(context.gl.TEXTURE_2D, 0, texture.__internalFormat, width, height, 0, texture.__format, context.gl.UNSIGNED_BYTE, null);
		@:nullSafety(Off)
		context.__bindGLTexture2D(null);
	}
}

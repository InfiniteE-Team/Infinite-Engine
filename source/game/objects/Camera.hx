package game.objects;

import animate.internal.RenderTexture;
import flash.geom.ColorTransform;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import core.render.shaders.CustomBlendShader;
import core.render.FixedBitmapData;

@:nullSafety
@:access(openfl.display.DisplayObject)
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.geom.ColorTransform)
class Camera extends flixel.FlxCamera {
	static final SHADER_BLEND_MODES:Array<String> = [
		"overlay",
		"hardlight",
		"darken",
		"lighten",
		"difference",
		"exclusion",
		"hue",
		"saturation",
		"color",
		"luminosity",
		"invert"
	];

	static final BLEND_TO_INT:Map<String, Int> = [
		"overlay" => 4,
		"hardlight" => 5,
		"darken" => 6,
		"lighten" => 7,
		"difference" => 8,
		"exclusion" => 9,
		"hue" => 10,
		"saturation" => 11,
		"color" => 12,
		"luminosity" => 13,
		"invert" => 14
	];

	var blendShader:CustomBlendShader;
	var backgroundFrame:FlxFrame;
	var blendRenderTexture:RenderTexture;
	var backgroundRenderTexture:RenderTexture;
	var cameraTexture:FixedBitmapData;
	var cameraMatrix:FlxMatrix;

	@:nullSafety(Off)
	public function new(?x:Float = 0.0, ?y:Float = 0.0, ?width:Int = 0, ?height:Int = 0, ?zoom:Float = 0.0) {
		super(x, y, width, height, zoom);

		blendShader = new CustomBlendShader();
		backgroundFrame = new FlxFrame(new FlxGraphic('', null));
		backgroundFrame.frame = new flixel.math.FlxRect();
		blendRenderTexture = new RenderTexture(this.width, this.height);
		backgroundRenderTexture = new RenderTexture(this.width, this.height);
		cameraMatrix = new FlxMatrix();
		cameraTexture = FixedBitmapData.create(this.width, this.height);

		pruneEmptyFilters();
	}

	public function pruneEmptyFilters():Void {
		if (filters == null)
			return;
		filters = filters.filter(f -> f != null);
		if (filters.length == 0)
			filters = null;
	}

	override function set_angle(val:Float):Float {
		return angle = val;
	}

	override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
			?shader:FlxShader):Void {
		var blendStr = blend != null ? @:privateAccess blend.toString().toLowerCase() : null;
		if (blendStr != null && SHADER_BLEND_MODES.contains(blendStr)) {
			core.render.BitmapDataUtil.drawCameraScreen(cameraTexture, this);

			backgroundFrame.frame.set(0, 0, this.width, this.height);
			this.clearDrawStack();
			this.canvas.graphics.clear();

			blendRenderTexture.init(this.width, this.height);
			blendRenderTexture.drawToCamera((cam, frameMatrix) -> {
				var px:Float = width / 2;
				var py:Float = height / 2;
				frameMatrix.copyFrom(matrix);
				frameMatrix.translate(-px, -py);
				frameMatrix.scale(this.scaleX, this.scaleY);
				frameMatrix.translate(px, py);
				cam.drawPixels(frame, pixels, frameMatrix, transform, null, smoothing, shader);
			});
			blendRenderTexture.render();

			blendShader.sourceSwag = blendRenderTexture.graphic.bitmap;
			blendShader.backgroundSwag = cameraTexture;
			blendShader.blendSwag = BLEND_TO_INT.get(blendStr) ?? 0;

			backgroundFrame.parent.bitmap = blendRenderTexture.graphic.bitmap;

			var scale:Float = Math.max(1, openfl.Lib.current.stage.window.scale);
			backgroundRenderTexture.init(Std.int(this.width * scale), Std.int(this.height * scale));
			backgroundRenderTexture.drawToCamera((cam, mat) -> {
				cam.zoom = this.zoom;
				mat.scale(scale, scale);
				cam.drawPixels(backgroundFrame, null, mat, canvas.transform.colorTransform, null, false, blendShader);
			});
			backgroundRenderTexture.render();

			cameraMatrix.identity();
			cameraMatrix.scale(1 / (this.scaleX * scale), 1 / (this.scaleY * scale));
			cameraMatrix.translate((width - width / this.scaleX) * 0.5, (height - height / this.scaleY) * 0.5);

			super.drawPixels(backgroundRenderTexture.graphic.imageFrame.frame, null, cameraMatrix, null, null, smoothing, null);
		} else {
			if (!FlxG.renderBlit && angle != 0) {
				matrix.translate(-width / 2, -height / 2);
				var rad:Float = angle * Math.PI / 180;
				matrix.rotateWithTrig(Math.cos(rad), Math.sin(rad));
				matrix.translate(width / 2, height / 2);
			}
			super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
		}
	}

	override function destroy():Void {
		super.destroy();
		blendRenderTexture.destroy();
		backgroundRenderTexture.destroy();
		cameraTexture.dispose();
	}
}

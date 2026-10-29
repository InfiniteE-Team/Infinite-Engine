package core.render.swf;

import foxlite.FoxModel;
import foxlite.FoxShader;
import foxlite.mesh.FoxMesh;
import foxlite.material.FoxMaterial;
import foxlite.material.FoxTriangleFace;
import openfl.display.MovieClip;
import core.render.swf.utils.*;

class SWFModel extends FoxModel {
	public var pixelSize:Float = 0.01;

	var mc:MovieClip;
	var currentFrame:Int = -1;
	var frameCache:Map<Int, Array<FoxMesh>> = new Map();

	public function new(swfPath:String, ?symbol:String = "", pixelSize:Float = 0.01) {
		super();
		this.pixelSize = pixelSize;
		#if sys
		if (sys.FileSystem.exists(swfPath)) {
			var ba = openfl.utils.ByteArray.fromBytes(sys.io.File.getBytes(swfPath));
			var loader = new openfl.display.Loader();
			FlxG.stage.addChild(loader);
			loader.loadBytes(ba);
			var content = loader.content;
			FlxG.stage.removeChild(loader);
			if (content != null) {
				var container:openfl.display.DisplayObjectContainer = cast content;
				mc = (symbol != null && symbol != "") ? cast container.getChildByName(symbol) : cast content;
			}
		}
		#else
		mc = openfl.Assets.getMovieClip('$swfPath:$symbol');
		#end

		if (mc != null)
			gotoFrame(1);
	}

	public function gotoFrame(frame:Int) {
		if (mc == null)
			return;
		if (frame == currentFrame)
			return;
		currentFrame = frame;
		mc.gotoAndStop(frame);

		if (frameCache.exists(frame)) {
			meshes = frameCache.get(frame);
			return;
		}

		var shapes = SWFShapeExtractor.extract(mc);
		var newMeshes:Array<FoxMesh> = [];

		for (shape in shapes) {
			var tess = SWFTessellator.tessellate(shape.contour, pixelSize);
			if (tess == null || tess.indices.length == 0)
				continue;

			var mat = FoxMaterial.create(FoxShader.fromAsset(FoxShader.BASIC));
			mat.shadowCulling = FoxTriangleFace.NONE;
			mat.setColor(shape.color);

			var mesh = new FoxMesh(mat);
			mesh.setArrays(tess.vertices, null, tess.indices, mat);
			mesh.calculateBounds(tess.vertices);
			newMeshes.push(mesh);
		}

		frameCache.set(frame, newMeshes);
		meshes = newMeshes;
	}

	public function playAnim(label:String) {
		if (mc == null)
			return;
		mc.gotoAndPlay(label);
	}

	override public function update(dt:Float) {
		super.update(dt);
		if (mc != null && mc.currentFrame != currentFrame)
			gotoFrame(mc.currentFrame);
	}

	override public function destroy() {
		frameCache = null;
		mc = null;
		super.destroy();
	}
}

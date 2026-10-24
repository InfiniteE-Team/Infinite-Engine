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

    var _mc:MovieClip;
    var _currentFrame:Int = -1;
    var _frameCache:Map<Int, Array<FoxMesh>> = new Map();

    public function new(swfPath:String, ?symbol:String = "", pixelSize:Float = 0.01) {
        super();
        this.pixelSize = pixelSize;
        _mc = openfl.Assets.getMovieClip('$swfPath:$symbol');
        if (_mc != null) gotoFrame(1);
    }

    public function gotoFrame(frame:Int) {
        if (frame == _currentFrame) return;
        _currentFrame = frame;
        _mc.gotoAndStop(frame);

        if (_frameCache.exists(frame)) {
            meshes = _frameCache.get(frame);
            return;
        }

        var shapes = SWFShapeExtractor.extract(_mc);
        var newMeshes:Array<FoxMesh> = [];

        for (shape in shapes) {
            var tess = SWFTessellator.tessellate(shape.contour, pixelSize);
            if (tess == null || tess.indices.length == 0) continue;

            var mat = FoxMaterial.create(FoxShader.fromAsset(FoxShader.BASIC));
            mat.shadowCulling = FoxTriangleFace.NONE;
            mat.setColor(shape.color);

            var mesh = new FoxMesh(mat);
            mesh.setArrays(tess.vertices, null, tess.indices, mat);
            mesh.calculateBounds(tess.vertices);
            newMeshes.push(mesh);
        }

        _frameCache.set(frame, newMeshes);
        meshes = newMeshes;
    }

    public function playAnim(label:String) {
        _mc.gotoAndPlay(label);
    }

    override public function update(dt:Float) {
        super.update(dt);
        if (_mc != null && _mc.currentFrame != _currentFrame)
            gotoFrame(_mc.currentFrame);
    }

    override public function destroy() {
        _frameCache = null;
        _mc = null;
        super.destroy();
    }
}
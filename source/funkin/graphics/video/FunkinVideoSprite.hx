package funkin.graphics.video;

#if VIDEO_ALLOWED
// V-Slice FunkinVideoSprite for scripts: the engine's safe video sprite, plus the zIndex stages sort by -JloorDev
@:keep
class FunkinVideoSprite extends states.cutscenes.SafeVideoSprite {
	public var zIndex:Int = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super(x, y);
	}
}
#end

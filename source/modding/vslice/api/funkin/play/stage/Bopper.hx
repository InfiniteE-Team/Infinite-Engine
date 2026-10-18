package funkin.play.stage;

// V-Slice Bopper for scripts: a sprite that dances on the beat with per-animation offsets -JloorDev
@:scriptable
@:keepSub
@:keep
class Bopper extends funkin.graphics.FunkinSprite {
	public var danceEvery:Float = 1;
	public var shouldBop:Bool = true;
	public var idleSuffix:String = '';
	public var shouldAlternate:Null<Bool> = null;
	public var hasDanced:Bool = false;

	var animOffsets:Map<String, Array<Float>> = new Map();

	public function new(danceEvery:Float = 1) {
		super();
		this.danceEvery = danceEvery;
	}

	public function setAnimationOffsets(name:String, x:Float, y:Float):Void
		animOffsets.set(name, [x, y]);

	override public function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void {
		super.playAnimation(name, restart, ignoreOther, reversed);
		var o = animOffsets.get(name);
		offset.set(o != null ? o[0] : 0, o != null ? o[1] : 0);
	}

	public function dance(forceRestart:Bool = false):Void {
		if (shouldAlternate == null)
			shouldAlternate = hasAnimation('danceLeft$idleSuffix');
		if (shouldAlternate) {
			playAnimation((hasDanced ? 'danceRight' : 'danceLeft') + idleSuffix, forceRestart);
			hasDanced = !hasDanced;
		} else
			playAnimation('idle$idleSuffix', forceRestart);
	}
}

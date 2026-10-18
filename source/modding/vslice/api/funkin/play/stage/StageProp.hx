package funkin.play.stage;

// a V-Slice stage prop: engine sprite plus the zIndex/danceEvery/playAnimation scripts touch -JloorDev
@:keep
class StageProp extends core.assets.FunkinSprite {
	public var zIndex:Int = 0;
	public var danceEvery:Float = 0;
	public var bopAnims:Array<String> = null;

	var bopStep:Int = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super(x, y);
	}

	public function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
		playAnim(name, restart);

	public function beatDance(beat:Float):Void {
		if (danceEvery <= 0 || beat % danceEvery != 0)
			return;
		var anims = bopAnims ?? (existsAnim('danceLeft') && existsAnim('danceRight') ? ['danceLeft', 'danceRight'] : (existsAnim('idle') ? ['idle'] : null));
		if (anims != null)
			playAnim(anims[bopStep++ % anims.length], true);
	}
}

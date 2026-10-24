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

	public function loadTexture(key:String):StageProp {
		var path = funkin.Paths.image(key);
		if (path != null)
			loadGraphic(path);
		return this;
	}

	public function loadSparrow(key:String):StageProp {
		var path = funkin.Paths.getSparrowAtlas(key);
		if (path != null)
			frames = path;
		return this;
	}

	public function loadTextureAtlas(key:String, ?library:String, ?settings:Dynamic):StageProp {
		var dir = funkin.Paths.animateAtlas(key, library);
		if (dir != null)
			frames = animate.FlxAnimateFrames.fromAnimate(dir);
		return this;
	}

	public function beatDance(beat:Float):Void {
		if (danceEvery <= 0 || beat % danceEvery != 0)
			return;
		var anims = bopAnims ?? (existsAnim('danceLeft')
			&& existsAnim('danceRight') ? ['danceLeft', 'danceRight'] : (existsAnim('idle') ? ['idle'] : null));
		if (anims != null)
			playAnim(anims[bopStep++ % anims.length], true);
	}
}

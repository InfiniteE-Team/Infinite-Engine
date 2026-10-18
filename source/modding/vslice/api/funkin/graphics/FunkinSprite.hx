package funkin.graphics;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import animate.internal.Frame;
import flixel.util.FlxColor;

// V-Slice's FunkinSprite on flixel-animate like V-Slice's own, so scripts can load texture atlases too
// .hxc scripts also get it in place of FlxSprite, since they set zIndex on it -JloorDev
@:scriptable
@:keepSub
@:keep
class FunkinSprite extends FlxAnimate {
	public var zIndex:Int = 0;

	public function new(x:Float = 0, y:Float = 0, ?graphic:Dynamic) {
		super(x, y, graphic);
	}

	public static function create(x:Float = 0, y:Float = 0, key:String):FunkinSprite
		return new FunkinSprite(x, y).loadTexture(key);

	public static function createSparrow(x:Float = 0, y:Float = 0, key:String):FunkinSprite
		return new FunkinSprite(x, y).loadSparrow(key);

	public static function createTextureAtlas(x:Float = 0, y:Float = 0, key:String, ?library:String, ?settings:Dynamic):FunkinSprite
		return new FunkinSprite(x, y).loadTextureAtlas(key, library, settings);

	public function loadTexture(key:String):FunkinSprite {
		var graphic = funkin.Paths.image(key);
		if (graphic != null)
			loadGraphic(graphic);
		else
			Console.log('[V-Slice] no image "$key"', true);
		return this;
	}

	public function loadSparrow(key:String):FunkinSprite {
		var atlas = funkin.Paths.getSparrowAtlas(key);
		if (atlas != null)
			frames = atlas;
		return this;
	}

	public function loadTextureAtlas(key:String, ?library:String, ?settings:Dynamic):FunkinSprite {
		var dir = funkin.Paths.animateAtlas(key, library);
		if (dir == null) {
			Console.log('[V-Slice] no texture atlas "$key"', true);
			return this;
		}
		frames = FlxAnimateFrames.fromAnimate(dir);
		return this;
	}

	public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite {
		makeGraphic(1, 1, color);
		scale.set(width, height);
		updateHitbox();
		return this;
	}

	public function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
		animation.play(name, restart, reversed);

	public function hasAnimation(name:String):Bool
		return animation.exists(name);

	public function isAnimationFinished():Bool
		return animation.finished;

	public function getCurrentAnimation():String
		return animation.name ?? '';

	public function getDefaultSymbol():String
		return library?.timeline?.name ?? '';

	public function getFramesWithKeyword(keyword:String):Array<Frame>
		return framesWithKeyword(library, keyword);

	public static function framesWithKeyword(lib:FlxAnimateFrames, keyword:String):Array<Frame> {
		var result:Array<Frame> = [];
		if (lib == null || keyword == null)
			return result;
		var libs = [lib];
		var added = @:privateAccess lib.addedCollections;
		if (added != null)
			for (c in added)
				libs.push(c);
		for (l in libs) {
			for (name in symbolNames(l)) {
				if (name.indexOf(keyword) < 0)
					continue;
				var symbol = l.getSymbol(name);
				if (symbol?.timeline == null)
					continue;
				for (layer in symbol.timeline.layers)
					for (frame in layer.frames ?? []) {
						frame.elements.splice(0, frame.elements.length);
						result.push(frame);
					}
			}
		}
		return result;
	}

	static function symbolNames(l:FlxAnimateFrames):Array<String> {
		var dict = @:privateAccess l.dictionary;
		var inlined = @:privateAccess l._symbolDictionary;
		var listed = @:privateAccess l._libraryList;
		var names:Array<String> = [for (k in dict.keys()) k];
		if (inlined != null)
			for (data in inlined)
				if (!names.contains(data.SN))
					names.push(data.SN);
		if (listed != null)
			for (n in listed)
				if (!names.contains(n))
					names.push(n);
		return names;
	}
}

package core.assets;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import utils.Point;
import core.json.extensions.SpriteData.ObjectData;
import flixel.graphics.frames.FlxAtlasFrames;
import game.graphics.shaders.CustomShader;

class FunkinSprite extends FlxAnimate {
	public var offsets:Map<String, Point> = new Map();

	private static var cache = new Map<String, Dynamic>();

	private static var cacheOffsets = new Map<String, Map<String, Int>>();

	override public function updateHitbox() {
		super.updateHitbox();
	}

	public function loadProps(props:ObjectData, path:String):Void {
		var assetPath = '$path/${props.path}';
		if (!cache.exists(assetPath)) {
			var loaded:Dynamic = Paths.getAnimated(assetPath);
			if (loaded != null)
				cache.set(assetPath, loaded);
			else
				trace('FunkinSprite could not load asset "$assetPath"');
		}

		trace('the file is: $assetPath');

		var cached:Dynamic = cache.get(assetPath);
		if (cached == null)
			return;

		var isSimpleImage:Bool = (cached is String);

		if (isSimpleImage)
			loadGraphic(cached, true, props.frameScale != null ? props.frameScale[0] : 0, props.frameScale != null ? props.frameScale[1] : 0);
		else
			frames = cached;

		var isAnimate = frames is FlxAnimateFrames;

		var filePathOffsets:Map<String, Int> = new Map();

		if (!isSimpleImage && !isAnimate && props.anims != null) {
			var merged = new Map<String, Bool>();
			for (anim in props.anims) {
				if (anim.filePath == null)
					continue;
				var fp:String = (anim.filePath is String) ? cast(anim.filePath, String) : (cast(anim.filePath, Array<Dynamic>))[0];
				if (fp == null || fp == props.path || merged.exists(fp))
					continue;
				merged.set(fp, true);
				var extraPath = '$path/$fp';
				if (!cache.exists(extraPath)) {
					var loaded:Dynamic = Paths.getAnimated(extraPath);
					if (loaded != null)
						cache.set(extraPath, loaded);
					else
						trace('Falling load multi asset "$extraPath"');
				}
				var extra:Dynamic = cache.get(extraPath);

				if (cacheOffsets.exists(assetPath))
					filePathOffsets = cacheOffsets.get(assetPath);
				else {
					filePathOffsets = new Map();
					if (extra != null && (extra is FlxAtlasFrames)) {
						filePathOffsets.set(fp, cast(frames, FlxAtlasFrames).frames.length);
						cast(frames, FlxAtlasFrames).addAtlas(cast extra);
						cacheOffsets.set(assetPath, filePathOffsets);
					}
				}
			}
		}

		if (props.anims != null) {
			for (anim in props.anims) {
				if (isSimpleImage) {
					animation.add(anim.name, anim.indices, anim.framerate, anim.looped);
				} else if (anim.indices?.length > 0) {
					var fp:Null<String> = anim.filePath == null ? null :
						((anim.filePath is String) ? cast(anim.filePath, String) : (cast(anim.filePath, Array<Dynamic>))[0]);
					var offset:Int = (fp != null && filePathOffsets.exists(fp)) ? filePathOffsets.get(fp) : 0;
					var offsetIndices:Array<Int> = offset > 0 ? anim.indices.map(i -> i + offset) : anim.indices;
					isAnimate ? this.anim.addBySymbolIndices(anim.name, anim.prefix, offsetIndices, anim.framerate,
						anim.looped) : animation.addByIndices(anim.name, anim.prefix, offsetIndices, "", anim.framerate, anim.looped);
				} else {
					isAnimate ? this.anim.addBySymbol(anim.name, anim.prefix, anim.framerate,
						anim.looped) : animation.addByPrefix(anim.name, anim.prefix, anim.framerate, anim.looped);
				}
			}
		}

		loadParams(props);

		if (props.scale != null)
			scale.set(props.scale[0], props.scale[1]);
		if (props.firstAnim != null)
			playAnim(props.firstAnim, true);

		updateHitbox();
	}

	public function loadMakeGraphic(props:ObjectData):Void
	{
		var color:String = '';
		if (props.color != null)
			color = props.color;
		makeGraphic(Std.int(props.scale[0]), Std.int(props.scale[1]),color);
		loadParams(props);

		updateHitbox();
	}

	public function loadParams(props:ObjectData):Void {
		if (props.position != null)
			setPosition(x + props.position[0], y + props.position[1]);
		
		if (props.blend != null)
			blend = props.blend;
		if (props.shader != null) {
			var sh = CustomShader.loadShader(props.shader);
			if (sh != null)
				shader = sh;
		}
		if (props.alpha != null)
			alpha = props.alpha;
		if (props.visible != null)
			visible = props.visible;
		if (props.flipX != null)
			flipX = props.flipX;
		if (props.flipY != null)
			flipY = props.flipY;
		if (props.antialiasing != null)
			antialiasing = props.antialiasing;
		if (props.scrollFactor != null)
			scrollFactor.set(props.scrollFactor[0],props.scrollFactor[1]);
	}

	public function playAnim(name:Null<String>, ?force:Bool = true) {
		if (!existsAnim(name)) {
			trace('$name Anim Not Existed! ERROR');
			return;
		}
		animation.play(name, force);
		activeOffsets(getAnimOffset());
	}

	/*
		private function disposeFromRAM():Void {
			if (graphic != null && graphic.bitmap != null)
				graphic.bitmap.disposeImage();
	}*/
	public static function clearCache() {
		for (key => frames in cache) {
			frames.destroy();
		}
		cacheOffsets.clear();
		cache.clear();
	}

	public function getAnimOffset():Null<Point>
		return offsets.get(anim.name) ?? {x: 0, y: 0};

	public function existsAnim(anim:String):Bool
		return animation.exists(anim);

	public function isFinished(anim:String):Bool
		return animation.curAnim.finished && existsAnim(anim);

	public function activeOffsets(off:Point) {
		offset.set(off.x, off.y);
	}

	override public function destroy() {
		offsets = null;
		super.destroy();
	}

	public function dance() {}
}

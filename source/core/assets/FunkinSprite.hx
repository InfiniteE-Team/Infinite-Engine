package core.assets;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import utils.Point;
import core.json.extensions.SpriteData.ObjectData;
import flixel.graphics.frames.FlxAtlasFrames;

class FunkinSprite extends FlxAnimate {
	public var offsets:Map<String, Point> = new Map();

	private static var cache = new Map<String, Dynamic>();

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
			loadGraphic(cached, true, props.frameScale[0] ?? 0, props.frameScale[1] ?? 0);
		else
			frames = cached;

		var isAnimate = frames is FlxAnimateFrames;

		if (!isSimpleImage && !isAnimate && props.anims != null) {
			var merged = new Map<String, Bool>();
			for (anim in props.anims) {
				if (anim.filePath == null) continue;
				var fp:String = (anim.filePath is String)
					? cast(anim.filePath, String)
					: (cast(anim.filePath, Array<Dynamic>))[0];
				if (fp == null || fp == props.path || merged.exists(fp)) continue;
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
				if (extra != null && (extra is FlxAtlasFrames))
					cast(frames, FlxAtlasFrames).addAtlas(cast extra);
			}
		}

		for (anim in props.anims) {
			if (isSimpleImage) {
				animation.add(anim.name, anim.indices, anim.framerate, anim.looped);
			} else if (anim.indices?.length > 0) {
				isAnimate ? this.anim.addBySymbolIndices(anim.name, anim.prefix, anim.indices, anim.framerate,
					anim.looped) : animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.framerate, anim.looped);
			} else {
				isAnimate ? this.anim.addBySymbol(anim.name, anim.prefix, anim.framerate,
					anim.looped) : animation.addByPrefix(anim.name, anim.prefix, anim.framerate, anim.looped);
			}
		}

		if (props.position != null)
			setPosition(x + props.position[0], y + props.position[1]);
		if (props.scale != null)
			scale.set(props.scale[0], props.scale[1]);
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
		if (props.firstAnim != null)
			playAnim(props.firstAnim,true);

		updateHitbox();
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
		cache.clear();
	}

	public function getAnimOffset():Null<Point>
		return offsets.get(anim.name) ?? {x:0,y:0};

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

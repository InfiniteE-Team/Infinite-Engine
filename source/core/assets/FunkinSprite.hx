package core.assets;

import flixel.math.FlxPoint;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import core.json.extensions.SpriteData.ObjectData;
import core.json.extensions.SpriteData.AnimData;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import game.graphics.shaders.CustomShader;

class FunkinSprite extends FlxAnimate {
	public var offsets:Map<String, Point> = new Map();

	public static var cacheOffsets = new Map<String, Map<String, Int>>();

	var _suffixes:Map<String, String> = new Map();

	// Tracks the last anim played — DO NOT use anim.name (FlxAnimateController),
	// that only updates for Adobe Animate atlas sprites, not Sparrow.
	public var currentAnim:String = '';

	override public function updateHitbox() {
		super.updateHitbox();
	}

	public function loadProps(props:ObjectData, path:String):Void {
		var assetPath = '$path/${props.path}';
		var loaded = Paths.getPath(assetPath,'animated');

		if (loaded == null) {
			Trace.traceOnce('FunkinSprite could not load asset "$assetPath"');
			return;
		}

		var isSimpleImage = (loaded is String);
		var isAnimate = false;

		if (isSimpleImage) {
			var scaleX = props.frameScale != null ? props.frameScale[0] : 0;
			var scaleY = props.frameScale != null ? props.frameScale[1] : 0;
			loadGraphic(loaded, true, scaleX, scaleY);
		} else {
			frames = cast(loaded, FlxFramesCollection);
			isAnimate = (frames is FlxAnimateFrames);
		}

		var filePathOffsets:Map<String, Int> = new Map();

		if (!isSimpleImage && !isAnimate && props.anims != null) {
			if (cacheOffsets.exists(assetPath)) {
				filePathOffsets = cacheOffsets.get(assetPath);
			} else {
				var merged = new Map<String, Bool>();
				for (anim in props.anims) {
					var animPath = getAnimFilePath(anim);
					if (animPath == null || animPath == props.path || merged.exists(animPath))
						continue;
					merged.set(animPath, true);

					var extraPath = '$path/$animPath';
					var extra = Paths.getAnimated(extraPath);
					if (extra == null)
						continue;

					var atlas = cast(frames, FlxAtlasFrames);
					if (extra is FlxAtlasFrames) {
						filePathOffsets.set(animPath, atlas.frames.length);
						atlas.addAtlas(cast extra);
					} else if (extra is String) {
						var fScale = getAnimFrameScale(props.anims, animPath);
						if (fScale != null) {
							var tileFrames = FlxTileFrames.fromGraphic(FlxG.bitmap.add(cast(extra, String)), FlxPoint.get(fScale[0], fScale[1]));
							filePathOffsets.set(animPath, atlas.frames.length);
							for (frame in (tileFrames.frames : Array<Dynamic>))
								atlas.frames.push(frame);
						}
					}
				}
				cacheOffsets.set(assetPath, filePathOffsets);
			}
		}

		for (anim in props.anims ?? []) {
			var suffix = anim.suffix ?? '';
			var fullAnimName = anim.name + suffix;
			_suffixes.set(anim.name, suffix);

			_registerAnim(fullAnimName);

			if (anim.offsets != null)
				offsets.set(fullAnimName, {x: anim.offsets[0], y: anim.offsets[1]});

			if (isSimpleImage) {
				animation.add(fullAnimName, anim.indices, anim.framerate, anim.looped);
			} else if (anim.indices?.length > 0) {
				var animPath = getAnimFilePath(anim);
				var offset = animPath != null ? (filePathOffsets.get(animPath) ?? 0) : 0;
				var indices = offset > 0 ? anim.indices.map(i -> i + offset) : anim.indices;
				isAnimate ? this.anim.addBySymbolIndices(fullAnimName, anim.prefix, indices, anim.framerate,
					anim.looped) : animation.addByIndices(fullAnimName, anim.prefix, indices, "", anim.framerate, anim.looped);
			} else {
				isAnimate ? this.anim.addBySymbol(fullAnimName, anim.prefix, anim.framerate,
					anim.looped) : animation.addByPrefix(fullAnimName, anim.prefix, anim.framerate, anim.looped);
			}
		}

		loadParams(props);
		if (props.scale != null)
			scale.set(props.scale[0], props.scale[1]);
		if (props.firstAnim != null)
			playAnim(props.firstAnim, true);
		updateHitbox();
	}

	static function getAnimFilePath(anim:AnimData):Null<String> {
		if (anim.filePath == null)
			return null;
		return (anim.filePath is String) ? cast anim.filePath : (cast anim.filePath : Array<Dynamic>)[0];
	}

	static function getAnimFrameScale(anims:Array<AnimData>, fp:String):Null<Array<Int>> {
		for (a in anims)
			if (a.frameScale != null && getAnimFilePath(a) == fp)
				return a.frameScale;
		return null;
	}

	public function loadMakeGraphic(props:ObjectData):Void {
		var color:String = '';
		if (props.color != null)
			color = props.color;
		makeGraphic(Std.int(props.scale[0]), Std.int(props.scale[1]), color);
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
			scrollFactor.set(props.scrollFactor[0], props.scrollFactor[1]);
	}

	public function playAnim(name:Null<String>, ?force:Bool = true) {
		var fullName = name + (_suffixes.get(name) ?? '');
		if (!existsAnim(fullName)) {
			Trace.traceOnce('$name Anim Not Existed! ERROR');
			return;
		}
		currentAnim = fullName;
		animation.play(fullName, force);
		activeOffsets(getAnimOffset());
	}

	public function getAnimOffset():Null<Point>
		return offsets.get(currentAnim) ?? {x: 0, y: 0};

	// Stores all registered anim names (both Sparrow and FlxAnimate systems)
	var _registeredAnims:Array<String> = [];

	// Override to register in both systems — called internally from loadProps
	function _registerAnim(name:String) {
		if (!_registeredAnims.contains(name))
			_registeredAnims.push(name);
	}

	public function existsAnim(name:String):Bool
		return animation.exists(name) || _registeredAnims.contains(name);

	public function isFinished(anim:String):Bool {
		var fullName = anim + (_suffixes.get(anim) ?? '');
		return animation.curAnim != null && animation.curAnim.name == fullName && animation.curAnim.finished;
	}

	public function activeOffsets(off:Point)
		offset.set(0 - off.x, 0 - off.y);

	override public function destroy() {
		offsets = null;
		_registeredAnims = null;
		super.destroy();
	}

	public function dance() {}
}

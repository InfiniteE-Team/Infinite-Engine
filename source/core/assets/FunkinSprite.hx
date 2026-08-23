package core.assets;

import flixel.math.FlxPoint;
import animate.FlxAnimateFrames;
import core.json.extensions.SpriteData.ObjectData;
import core.json.extensions.SpriteData.AnimData;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import game.graphics.shaders.CustomShader;

class FunkinSprite extends animate.FlxAnimate {
	public var offsets:Map<String, Point> = new Map();

	public static var cacheOffsets = new Map<String, Map<String, Int>>();

	var _suffixes:Map<String, String> = new Map();

	var _assetLoaded:Bool = false;

	// Tracks the last anim played — DO NOT use anim.name (FlxAnimateController),
	// that only updates for Adobe Animate atlas sprites, not Sparrow.
	public var currentAnim:String = '';

	public function new(?x:Float = 0, ?y:Float = 0, ?usesLoadProps:Bool = false) {
		super(x, y);
		if (usesLoadProps) {
			_assetLoaded = true;
			@:privateAccess
			this._frame = null;
			this.graphic = null;
		}
	}

	override public function updateHitbox() {
		super.updateHitbox();
	}

	// RUNTIME LOAD GRAPHICS IMAGES!111!
	override public function loadGraphic(graphic:flixel.system.FlxAssets.FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false,
			?key:String):flixel.FlxSprite {
		if ((graphic is String)) {
			var path:String = cast graphic;
			if (path != null && sys.FileSystem.exists(path)) {
				if (sys.FileSystem.exists('$path/Animation.json')) {
					frames = cast FlxAnimateFrames.fromAnimate(path);
					_assetLoaded = true;
					return this;
				}

				var bmp = openfl.display.BitmapData.fromFile(path);
				if (bmp == null)
					return super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);

				var flxGraphic = flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, path);
				flxGraphic.persist = true;
				@:privateAccess flxGraphic.bitmap.getTexture(FlxG.stage.context3D);
				flxGraphic.bitmap.disposeImage();

				var xmlPath = path.substr(0, path.lastIndexOf('.')) + '.xml';
				if (sys.FileSystem.exists(xmlPath)) {
					frames = FlxAtlasFrames.fromSparrow(flxGraphic, sys.io.File.getContent(xmlPath));
					_assetLoaded = true;
					return this;
				}

				var jsonPath = path.substr(0, path.lastIndexOf('.')) + '.json';
				if (sys.FileSystem.exists(jsonPath)) {
					frames = FlxAtlasFrames.fromTexturePackerJson(flxGraphic, sys.io.File.getContent(jsonPath));
					_assetLoaded = true;
					return this;
				}

				var txtPath = path.substr(0, path.lastIndexOf('.')) + '.txt';
				if (sys.FileSystem.exists(txtPath)) {
					frames = FlxAtlasFrames.fromLibGdx(flxGraphic, sys.io.File.getContent(txtPath));
					_assetLoaded = true;
					return this;
				}

				return super.loadGraphic(flxGraphic, animated, frameWidth, frameHeight, unique, key ?? path);
			}
		}
		return super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
	}

	public function loadProps(props:ObjectData, path:String):Void {
		var assetPath = '$path/${props.path}';

		var loaded = Paths.getPath(assetPath, 'animated');

		if (loaded == null) {
			Trace.traceOnce('FunkinSprite could not load asset "$assetPath"');
			return;
		}

		var isSimpleImage = (loaded is String) || (loaded is flixel.graphics.FlxGraphic);
		var isAnimate = false;

		if (isSimpleImage) {
			if (props.frameScale != null) {
				loadGraphic(loaded, true, props.frameScale[0], props.frameScale[1]);
			} else {
				loadGraphic(loaded);
			}
		} else {
			frames = cast(loaded, FlxFramesCollection);
			isAnimate = (frames is FlxAnimateFrames);
		}

		var filePathOffsets:Map<String, Int> = new Map();

		if (!isSimpleImage && !isAnimate && props.anims != null)
			filePathOffsets = loadAtlasOffsets(props, path);

		for (anim in props.anims ?? []) {
			var suffix = anim.suffix ?? '';
			var fullAnimName = anim.name + suffix;
			_suffixes.set(anim.name, suffix);
			_registerAnim(fullAnimName);

			if (anim.offsets != null)
				offsets.set(fullAnimName, {x: anim.offsets[0], y: anim.offsets[1]});

			if (isSimpleImage) {
				animation.add(fullAnimName, anim.indices, anim.framerate, anim.looped);
				continue;
			}

			var hasIndices = anim.indices?.length > 0;
			var animPath = getAnimFilePath(anim);
			var offset = animPath != null ? (filePathOffsets.get(animPath) ?? 0) : 0;

			var finalIndices:Array<Int> = null;
			if (hasIndices) {
				finalIndices = offset > 0 ? anim.indices.map(i -> i + offset) : anim.indices;
			}

			addAnim(fullAnimName, anim.prefix ?? (animPath != null ? animPath : anim.name), anim.framerate ?? 24, anim.looped ?? true, finalIndices);
		}

		loadParams(props);
		if (props.scale != null)
			scale.set(props.scale[0], props.scale[1]);
		if (props.firstAnim != null)
			playAnim(props.firstAnim, true);
		updateHitbox();

		if (graphic != null && graphic.bitmap != null) {
			graphic.bitmap.disposeImage(); // clears RAM to use only the memory in VRAM
		}

		_assetLoaded = true;
	}

	public function addAnim(name:String, prefix:String, fps:Float = 24, looped:Bool = true, ?indices:Array<Int>):Void {
		var hasIndices:Bool = indices != null && indices.length > 0;

		if (isAnimate) {
			if (hasIndices) {
				this.anim.addBySymbolIndices(name, prefix, indices, fps, looped);
			} else {
				if (hasFrameLabel(prefix)) {
					this.anim.addByFrameLabel(name, prefix, fps, looped);
				} else {
					this.anim.addBySymbol(name, prefix, fps, looped);
				}
			}
		} else {
			if (hasIndices) {
				if (prefix != null && prefix != "") {
					animation.addByIndices(name, prefix, indices, "", fps, looped);
				} else {
					animation.add(name, indices, Std.int(fps), looped);
				}
			} else {
				animation.addByPrefix(name, prefix, fps, looped);
			}
		}
	}

	function hasFrameLabel(name:String):Bool {
		try {
			final tl:animate.internal.Timeline = this.library.timeline;
			if (tl != null)
				for (layer in tl.layers)
					for (frame in layer.frames)
						if (frame.name != null && frame.name.rtrim() == name)
							return true;

			@:privateAccess
			final collections = this.library.addedCollections;
			if (collections != null) {
				for (col in collections) {
					@:privateAccess
					final colTl:animate.internal.Timeline = col.timeline;
					if (colTl == null)
						continue;
					for (layer in colTl.layers)
						for (frame in layer.frames)
							if (frame.name != null && frame.name.rtrim() == name)
								return true;
				}
			}
		} catch (_) {}
		return false;
	}

	private function loadAtlasOffsets(props:ObjectData, path:String):Map<String, Int> {
		var assetPath = '$path/${props.path}';
		if (cacheOffsets.exists(assetPath))
			return cacheOffsets.get(assetPath);

		var offsets = new Map<String, Int>();
		var atlas = cast(frames, FlxAtlasFrames);
		var merged = new Map<String, Bool>();

		for (anim in props.anims) {
			var animPath = getAnimFilePath(anim);
			if (animPath == null || animPath == props.path || merged.exists(animPath))
				continue;
			merged.set(animPath, true);

			var extra = Paths.getAnimated('$path/$animPath');
			if (extra == null)
				continue;

			if (extra is FlxAtlasFrames) {
				offsets.set(animPath, atlas.frames.length);
				atlas.addAtlas(cast extra);
			} else if (extra is String) {
				var fScale = getAnimFrameScale(props.anims, animPath);
				if (fScale == null)
					continue;
				var tileFrames = FlxTileFrames.fromGraphic(FlxG.bitmap.add(cast(extra, String)), FlxPoint.get(fScale[0], fScale[1]));
				var offsetIdx = atlas.frames.length;
				for (frame in (tileFrames.frames : Array<Dynamic>))
					atlas.frames.push(frame);
				offsets.set(animPath, offsetIdx);
			}
		}

		cacheOffsets.set(assetPath, offsets);
		return offsets;
	}

	static function getAnimFilePath(anim:AnimData):Null<String> {
		if (anim.filePath == null)
			return null;
		return (anim.filePath is String) ? cast anim.filePath : (cast anim.filePath : Array<Dynamic>)[0];
	}

	static function getAnimFrameScale(anims:Array<AnimData>, fp:String):Null<Array<Int>> {
		for (anim in anims)
			if (anim.frameScale != null && getAnimFilePath(anim) == fp)
				return anim.frameScale;
		return null;
	}

	public function loadMakeGraphic(props:ObjectData):Void {
		var color:String = '';
		if (props.color != null)
			color = props.color;
		makeGraphic(Std.int(props.scale[0]), Std.int(props.scale[1]), color);
		loadParams(props);
		updateHitbox();
		_assetLoaded = true;
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

		if (props.antialiasing != null) {
			if (props.antialiasing)
				antialiasing = SaveData.data.antialiasing;
			else
				antialiasing = false;
		}

		if (props.scrollFactor != null)
			scrollFactor.set(props.scrollFactor[0], props.scrollFactor[1]);
	}

	public function playAnim(name:Null<String>, ?force:Bool = true) {
		var fullName = name + (_suffixes.get(name) ?? '');
		if (!existsAnim(fullName)) {
			Trace.traceOnce('$name Anim Not Existed!', true);
			return;
		}
		currentAnim = fullName;
		animation.play(fullName, force);
		activeOffsets(getAnimOffset());
	}

	public function getAnimOffset():Null<Point>
		return offsets.get(currentAnim) ?? {x: 0, y: 0};

	var _registeredAnims:Array<String> = [];

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

	override public function draw():Void {
		if (!_assetLoaded)
			return;
		if (isAnimate && (timeline == null || timeline.layers == null || timeline.layers.length == 0))
			return;
		super.draw();
	}

	public function dance() {}

	override public function destroy() {
		if (anim != null) {
			anim.pause();
		}

		if (isAnimate && (timeline == null || anim == null)) {
			frames = null;
		}

		try {
			super.destroy();
		} catch (e:Dynamic) {
			Trace.traceOnce('Warning: Destroy FunkinSprite: $e');
		}

		offsets = null;
		_suffixes = null;
		_registeredAnims = null;
	}
}

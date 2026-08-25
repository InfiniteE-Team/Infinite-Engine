package states.preload;

import sys.FileSystem;
import openfl.media.Sound as OflSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import core.rhythm.audio.Sound;

/**
 * Runs immediately after ConfigMain, before the mod's initial state.
 * Scans `images/`, `sounds/` and `music/` from the active mod and base assets,
 * then bulk-caches them using `Paths.cacheAutoAsync` (graphics) and
 * `Sound.streamedCache` (audio) so the first state switch is lag-free.
 */
class FunkinPreloader extends MusicBeatState {
	/**
	 * Width of each progress bar, in pixels.
	 */
	static final BAR_WIDTH:Int = 1000;

	/**
	 * Height of each progress bar segment, in pixels.
	 */
	static final BAR_HEIGHT:Int = 10;

	/**
	 * Duration of the fade-out after all assets are cached, in seconds.
	 */
	static final FADE_TIME:Float = 0.35;

	/**
	 * Gap between the graphics bar and the audio bar, in pixels.
	 */
	static final BAR_GAP:Float = 36;

	/**
	 * Vertical center of the bar cluster, as a fraction of screen height.
	 */
	static final BAR_CENTER_Y:Float = 0.685;

	/**
	 * Lambda that produces the state to switch to once preloading finishes.
	 */
	var nextState:() -> MusicBeatState;

	/**
	 * Current machine state driving the preload pipeline.
	 */
	var currentStep:FunkinPreloadStep = FunkinPreloadStep.Scanning;

	// ─── Asset queues ─────────────────────────────────────────────────────────

	/**
	 * Relative image keys collected during the scan step, fed to `Paths.cacheAutoAsync`.
	 * Example entry: `"characters/boyfriend"`
	 */
	var imageQueue:Array<String> = [];

	/**
	 * Absolute OGG paths collected during the scan step, fed to `Sound.streamedCache`.
	 */
	var audioQueue:Array<String> = [];

	var totalImages:Int = 0;
	var loadedImages:Int = 0;
	var totalAudio:Int = 0;
	var loadedAudio:Int = 0;

	var graphicsDone:Bool = false;
	var audioDone:Bool = false;

	var launched:Bool = false;

	var progressLines:openfl.display.Sprite;

	var bg:FlxSprite;

	var statusText:FlxText;
	var stepText:FlxText;

	var barBgGraphics:FlxSprite;
	var barGraphics:FlxBar;
	var labelGraphics:FlxText;

	var barBgAudio:FlxSprite;
	var barAudio:FlxBar;
	var labelAudio:FlxText;

	/**
	 * Read by `barGraphics` via reflection to get the current fill ratio.
	 */
	public var graphicsProgress(get, never):Float;

	function get_graphicsProgress():Float
		return totalImages > 0 ? (loadedImages / totalImages) : 1.0;

	/**
	 * Read by `barAudio` via reflection to get the current fill ratio.
	 */
	public var audioProgress(get, never):Float;

	function get_audioProgress():Float
		return totalAudio > 0 ? (loadedAudio / totalAudio) : 1.0;

	public function new(nextState:() -> MusicBeatState) {
		super();
		this.nextState = nextState;
	}

	override public function create():Void {
		MusicBeatState.skipNextTransIn = true;
		super.create();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		buildUI();
		runScan();

		if (totalImages == 0 && totalAudio == 0) {
			immediatelyLaunch();
			return;
		}

		currentStep = FunkinPreloadStep.CachingGraphics;
		updateStatusText();

		dispatchGraphics();
		dispatchAudio();
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
	}

	function buildUI():Void {
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		var barX:Float = (FlxG.width - BAR_WIDTH) / 2;
		var barY:Float = FlxG.height * BAR_CENTER_Y;
		var audioBarY:Float = barY + BAR_HEIGHT + BAR_GAP;

		statusText = new FlxText(barX, barY - 60, BAR_WIDTH, '');
		statusText.setFormat(Paths.getPath('DS-Digital.ttf', 'font'), 30, core.EngineData.COLOR_PRELOADER_BAR, LEFT);
		add(statusText);

		stepText = new FlxText(barX, barY - 30, BAR_WIDTH, '');
		stepText.setFormat(Paths.getPath('DS-Digital.ttf', 'font'), 14, core.EngineData.COLOR_PRELOADER_BAR, LEFT);
		add(stepText);

		barBgGraphics = new FlxSprite(barX, barY).makeGraphic(BAR_WIDTH, BAR_HEIGHT, 0xFF222222);
		add(barBgGraphics);

		barGraphics = new FlxBar(barX, barY, LEFT_TO_RIGHT, BAR_WIDTH, BAR_HEIGHT, this, 'graphicsProgress', 0, 1);
		barGraphics.createFilledBar(FlxColor.TRANSPARENT, core.EngineData.COLOR_PRELOADER_BAR);
		add(barGraphics);

		labelGraphics = new FlxText(barX, barY + BAR_HEIGHT + 10, BAR_WIDTH, 'Graphics  0 / 0');
		labelGraphics.setFormat(Paths.getPath('DS-Digital.ttf', 'font'), 12, 0xFF666666, LEFT);
		add(labelGraphics);

		barBgAudio = new FlxSprite(barX, audioBarY).makeGraphic(BAR_WIDTH, BAR_HEIGHT, 0xFF222222);
		add(barBgAudio);

		barAudio = new FlxBar(barX, audioBarY, LEFT_TO_RIGHT, BAR_WIDTH, BAR_HEIGHT, this, 'audioProgress', 0, 1);
		barAudio.createFilledBar(FlxColor.TRANSPARENT, core.EngineData.COLOR_PRELOADER_BAR);
		add(barAudio);

		labelAudio = new FlxText(barX, audioBarY + BAR_HEIGHT + 5, BAR_WIDTH, 'Audio  0 / 0');
		labelAudio.setFormat(Paths.getPath('DS-Digital.ttf', 'font'), 12, 0xFF666666, LEFT);
		add(labelAudio);

		var progressLines:FlxSprite = new FlxSprite(0, FlxG.height * 0.67);
		progressLines.makeGraphic(FlxG.width, 30, FlxColor.TRANSPARENT, true);
		var shape:openfl.display.Shape = new openfl.display.Shape();
		shape.graphics.lineStyle(2, core.EngineData.COLOR_PRELOADER_BAR);
		shape.graphics.drawRect(-2, 0, FlxG.width + 4, 30);
		progressLines.pixels.draw(shape);
		progressLines.dirty = true;
		add(progressLines);
	}

	function updateStatusText():Void {
		if (statusText == null)
			return;

		statusText.text = currentStep.getLabel();
		stepText.text = currentStep.getSubLabel(totalImages, totalAudio, loadedImages, loadedAudio);
	}

	/**
	 * Walks the active mod's asset directories (and the base `assets/` folder)
	 * to collect every PNG and OGG into their respective queues.
	 * Skips files already present in `Paths.cache` or `Sound.streamedCache`.
	 */
	function runScan():Void {
		currentStep = FunkinPreloadStep.Scanning;
		updateStatusText();

		var roots:Array<String> = [];

		if (modding.mods.ModsRegistry.onMod && modding.mods.ModsRegistry.currentMod != null && modding.mods.ModsRegistry.currentMod != '')
			roots.push('${core.assets.Library.modsFolder}/${modding.mods.ModsRegistry.currentMod}');

		roots.push(core.assets.Library.baseFolder);

		for (root in roots) {
			scanForImages('$root/images', '$root/images');
			scanForAudio('$root/sounds', '$root/sounds');
			scanForAudio('$root/music', '$root/music');
			scanForAudio('$root/songs', '$root/songs');
		}

		totalImages = imageQueue.length;
		totalAudio = audioQueue.length;

		labelGraphics.text = 'Graphics  0 / $totalImages';
		labelAudio.text = 'Audio  0 / $totalAudio';
	}

	/**
	 * Recursively collects PNG paths from `dir` as relative cache keys.
	 * Already-cached files are skipped to avoid redundant GPU uploads.
	 * @param dir     Directory to walk.
	 * @param rootDir The scan root — used to strip the prefix from each key.
	 */
	function scanForImages(dir:String, rootDir:String):Void {
		if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir))
			return;

		var cleanDir = dir.replace('\\', '/');
		var cleanRootDir = rootDir.replace('\\', '/');

		for (item in FileSystem.readDirectory(dir)) {
			var fullPath = '$cleanDir/$item'.replace('\\', '/');

			if (FileSystem.isDirectory(fullPath)) {
				scanForImages(fullPath, rootDir);
			} else if (item.endsWith('.png')) {
				var key = fullPath.replace('$cleanRootDir/', '').replace('.png', '');
				if (!imageQueue.contains(key))
					imageQueue.push(key);
			}
		}
	}

	/**
	 * Recursively collects absolute OGG paths from `dir`.
	 * Already-streamed files are skipped so we don't double-buffer them.
	 * @param dir     Directory to walk.
	 * @param rootDir Unused structurally; kept symmetric with `scanForImages`.
	 */
	function scanForAudio(dir:String, rootDir:String):Void {
		if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir))
			return;

		for (item in FileSystem.readDirectory(dir)) {
			var fullPath = '$dir/$item';

			if (FileSystem.isDirectory(fullPath)) {
				scanForAudio(fullPath, rootDir);
			} else if (item.endsWith('.ogg')) {
				var absPath = FileSystem.absolutePath(fullPath);

				if (!Sound.streamedCache.exists(absPath) && !audioQueue.contains(absPath))
					audioQueue.push(absPath);
			}
		}
	}

	/**
	 * Fires off all image cache jobs via `Paths.cacheAutoAsync`.
	 * Each callback increments `loadedImages` and ticks the completion check.
	 */
	function dispatchGraphics():Void {
		if (totalImages == 0) {
			graphicsDone = true;
			checkAllDone();
			return;
		}

		for (key in imageQueue) {
			try {
				Paths.cacheAutoAsync(key, function(_):Void {
					loadedImages++;
					labelGraphics.text = 'Graphics  $loadedImages / $totalImages';
					checkAllDone();
				});
			} catch (e:Dynamic) {
				Trace.traceOnce('[FunkinPreloader]: Error process image/atlas: $key - $e', true);
				loadedImages++;
				checkAllDone();
			}
		}
	}

	/**
	 * Fires off all audio cache jobs on background threads.
	 * Each OGG is decoded off the main thread and inserted into
	 * `Sound.streamedCache` (the same map `Sound.onSoundStreamed` reads),
	 * so playback never hits the disk again after this point.
	 */
	function dispatchAudio():Void {
		if (totalAudio == 0) {
			audioDone = true;
			checkAllDone();
			return;
		}

		for (absPath in audioQueue) {
			sys.thread.Thread.create(function():Void {
				if (Sound.streamedCache.exists(absPath)) {
					haxe.MainLoop.runInMainThread(function():Void {
						loadedAudio++;
						labelAudio.text = 'Audio  $loadedAudio / $totalAudio';
						checkAllDone();
					});
					return;
				}

				var oflSound:OflSound = null;

				try {
					#if lime_cffi
					var buffer = lime.media.AudioBuffer.fromFile(absPath);
					if (buffer != null)
						oflSound = OflSound.fromAudioBuffer(buffer);
					#else
					oflSound = OflSound.fromFile(absPath);
					#end
				} catch (e:Dynamic) {
					trace('[PreloadState] Audio decode failed: $absPath — $e');
				}

				haxe.MainLoop.runInMainThread(function():Void {
					if (oflSound != null && !Sound.streamedCache.exists(absPath))
						Sound.streamedCache.set(absPath, oflSound);

					loadedAudio++;
					labelAudio.text = 'Audio  $loadedAudio / $totalAudio';
					checkAllDone();
				});
			});
		}
	}

	/**
	 * Called after every individual asset finishes loading.
	 * When both graphics and audio are fully cached, kicks off the fade-out.
	 */
	function checkAllDone():Void {
		if (launched)
			return;

		if (!graphicsDone && loadedImages >= totalImages) {
			graphicsDone = true;
			currentStep = FunkinPreloadStep.CachingAudio;
			updateStatusText();
		}

		if (!audioDone && loadedAudio >= totalAudio)
			audioDone = true;

		if (graphicsDone && audioDone) {
			currentStep = FunkinPreloadStep.Complete;
			updateStatusText();
			fadeAndLaunch();
		}
	}

	/**
	 * Fades out all UI elements and then switches to `nextState`.
	 */
	function fadeAndLaunch():Void {
		var tweenOpts = {ease: FlxEase.quadIn};

		FlxTween.tween(bg, {alpha: 0}, FADE_TIME, tweenOpts);
		FlxTween.tween(statusText, {alpha: 0}, FADE_TIME * 0.7, tweenOpts);
		FlxTween.tween(stepText, {alpha: 0}, FADE_TIME * 0.7, tweenOpts);
		FlxTween.tween(barBgGraphics, {alpha: 0}, FADE_TIME * 0.7, tweenOpts);
		FlxTween.tween(barGraphics, {alpha: 0}, FADE_TIME * 0.7, tweenOpts);
		FlxTween.tween(labelGraphics, {alpha: 0}, FADE_TIME * 0.7, tweenOpts);
		FlxTween.tween(barBgAudio, {alpha: 0}, FADE_TIME * 0.7, tweenOpts);
		FlxTween.tween(barAudio, {alpha: 0}, FADE_TIME * 0.7, tweenOpts);
		FlxTween.tween(labelAudio, {alpha: 0}, FADE_TIME * 0.7, tweenOpts);

		haxe.Timer.delay(immediatelyLaunch, Std.int(FADE_TIME * 1000));
	}

	/**
	 * Performs the actual state switch.
	 * Guards against being called more than once (e.g. from both the
	 * zero-assets fast-path and the normal fade-out path).
	 */
	function immediatelyLaunch():Void {
		if (launched)
			return;

		launched = true;
		State.skipNextAudioClear = true;
		MusicBeatState.skipNextCacheClear = true;
		MusicBeatState.switchState(nextState);
	}

	override public function destroy():Void {
		bg = null;
		statusText = null;
		stepText = null;
		barBgGraphics = null;
		barGraphics = null;
		labelGraphics = null;
		barBgAudio = null;
		barAudio = null;
		labelAudio = null;
		nextState = null;
		imageQueue = null;
		audioQueue = null;
		@:privateAccess
		super.destroy();
	}
}

/**
 * Drives the status text shown during each phase of the preload pipeline.
 */
enum abstract FunkinPreloadStep(String) to String {
	/**
	 * Walking asset directories to build the image and audio queues.
	 */
	public var Scanning;

	/**
	 * Uploading PNGs to the GPU via `Paths.cacheAutoAsync`.
	 * Sparrow XML, TexturePacker JSON, LibGDX txt and FlxAnimate folders
	 * are parsed automatically by that function.
	 */
	public var CachingGraphics;

	/**
	 * Decoding OGGs into `Sound.streamedCache` on background threads.
	 * Runs concurrently with `CachingGraphics`.
	 */
	public var CachingAudio;

	/**
	 * All assets cached — fading out and switching to the initial state.
	 */
	public var Complete;

	/**
	 * Returns the large status label shown above the progress bars.
	 */
	public function getLabel():String {
		return switch (this) {
			case Scanning: 'Scanning assets';
			case CachingGraphics: 'Caching graphics';
			case CachingAudio: 'Caching audio';
			case Complete: 'Done!';
			default: '';
		}
	}

	/**
	 * Returns the smaller sub-label with live counters.
	 * @param totalImages   Total images to cache.
	 * @param totalAudio    Total audio files to cache.
	 * @param loadedImages  Images cached so far.
	 * @param loadedAudio   Audio files cached so far.
	 */
	public function getSubLabel(totalImages:Int, totalAudio:Int, loadedImages:Int, loadedAudio:Int):String {
		return switch (this) {
			case Scanning:
				'Building asset queue...';
			case CachingGraphics:
				'Graphics $loadedImages / $totalImages  ·  Audio $loadedAudio / $totalAudio';
			case CachingAudio:
				'Graphics done  ·  Audio $loadedAudio / $totalAudio';
			case Complete:
				'Graphics $totalImages / $totalImages  ·  Audio $totalAudio / $totalAudio';
			default:
				'';
		}
	}
}

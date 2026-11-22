package states.menus;

import states.HotReloading;
import core.json.song.SongConfig;
import core.json.game.objects.*;
import states.menus.objects.FunkinLoadingCharacter;
import core.json.menus.loading.LoadingCharacterData;

class LoadingState extends MusicBeatState {
	public var onQueueCollect:Null<LoadingState->Void>;

	public var onStateReady:Null<() -> MusicBeatState>;

	var total:Int = 0;
	var loaded:Int = 0;
	var done:Bool = false;

	public var queue:Array<String> = [];

	public var audioQueue:Array<String> = [];

	public static final BAR_PAD:Int = 16;

	public var barTargetX:Float = 0;

	var barStartX:Float = 0;

	// loading more at once spikes the RAM -JloorDev
	static inline final MAX_LOADING:Int = 2;

	var loading:Int = 0;
	var nextImage:Int = 0;
	var nextAudio:Int = 0;
	var destroyed:Bool = false;

	var bar:Null<core.assets.FunkinSprite> = null;
	var micStand:Null<core.assets.FunkinSprite> = null;
	var character:Null<FunkinLoadingCharacter> = null;

	var dataList:Array<LoadingCharacterData> = [];

	var prebuiltState:Null<MusicBeatState> = null;

	var prebuiltInterface:Null<HotReloading> = null;
	var isPrebuiltDone:Bool = false;

	public function new(?onQueue:LoadingState->Void, ?onReady:() -> MusicBeatState) {
		super();
		this.onQueueCollect = onQueue;
		this.onStateReady = onReady;

		bar = new core.assets.FunkinSprite(0, 0, true);
		micStand = new core.assets.FunkinSprite(0, 0, true);
		character = new FunkinLoadingCharacter();
	}

	public static function forSong(songFolder:String, curDifficulty:Int = 0):LoadingState {
		return new LoadingState((ls) -> ls.collectSongQueue(songFolder, curDifficulty), () -> new game.PlayState(songFolder, curDifficulty));
	}

	override public function create() {
		super.create();

		if (FlxG.mouse != null)
			FlxG.mouse.visible = false;

		#if HSCRIPT_ALLOWED
		initScript();
		script.executeAll();
		script.call("onCreate", []);
		#end

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		buildLoadingUI();

		if (onStateReady != null) {
			prebuiltState = onStateReady();
			try {
				prebuiltInterface = cast(prebuiltState, HotReloading);
			} catch (_:Dynamic) {
				prebuiltInterface = null;
			}
		}

		if (onQueueCollect != null)
			onQueueCollect(this);

		total = queue.length + audioQueue.length;

		if (total == 0 && isPrebuiltReady())
			onAllLoaded();
	}

	function buildLoadingUI() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable("onCreateCancel", []))
			return;
		#end

		loadCharacterData();
		getCharacter();

		micStand.loadGraphic(Paths.getPath('menus/loading/mic-stand', 'image'));
		micStand.scale.set(0.24, 0.24);
		micStand.updateHitbox();
		micStand.x = FlxG.width - (micStand.width + 45);
		micStand.y = FlxG.height - (micStand.height + 30);
		add(micStand);

		barTargetX = barStartX = micStand.x;

		bar.alpha = 0.9;
		bar.makeSolidColor(Std.int(micStand.width) + BAR_PAD, Std.int(micStand.height) + BAR_PAD, flixel.util.FlxColor.BLACK);
		bar.setPosition(barTargetX, micStand.y);
		add(bar);

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end
	}

	final charNames:Array<String> = [];

	function loadCharacterData():Void {
		final folder = core.assets.Library.findLib('menus/loading/characters');
		if (folder == null || !sys.FileSystem.exists(folder) || !sys.FileSystem.isDirectory(folder))
			return;

		for (file in sys.FileSystem.readDirectory(folder)) {
			final fullPath = '$folder/$file';
			if (!sys.FileSystem.isDirectory(fullPath))
				continue;
			var data:LoadingCharacterData = FormatJson.readJson('$fullPath/$file.json');
			if (data != null) {
				dataList.push(data);
				charNames.push(file);
			}
		}
	}

	public function getCharacter():Void {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable("onGetCharacterCancel", []))
			return;
		#end

		if (charNames.length == 0)
			return;

		var weights:Array<Float> = [];
		for (data in dataList)
			weights.push(data.weight);

		var characterData:LoadingCharacterData = FlxG.random.getObject(dataList, weights);
		var idx:Int = dataList.indexOf(characterData);
		var characterId:String = charNames[idx];
		character.loadCharacter(characterData, Paths.getPath('menus/loading/characters/$characterId/$characterId', 'animated'));
		add(character);

		#if HSCRIPT_ALLOWED
		script.call("postGetCharacter", []);
		#end
	}

	var queueSet = new Map<String, Bool>();
	var audioQueueSet = new Map<String, Bool>();

	public inline function enqueue(path:String) {
		if (path != null && !queueSet.exists(path)) {
			queueSet.set(path, true);
			queue.push(path);
		}
	}

	public function enqueueAudio(path:String) {
		if (path == null)
			return;
		var abs = sys.FileSystem.absolutePath(path);
		if (core.audio.Sound.isStreamable(abs))
			return;
		if (!audioQueueSet.exists(abs) && !core.audio.Sound.streamedCache.exists(abs)) {
			audioQueueSet.set(abs, true);
			audioQueue.push(abs);
		}
	}

	function collectSongQueue(songFolder:String, curDifficulty:Int) {
		var song:Null<SongConfig> = new SongConfig();
		song.configSong(songFolder, core.rhythm.DiffsUtils.difficulties[curDifficulty]);

		if (song.songData == null)
			return;

		collectStageAssets(song.stage ?? 'stage');

		for (charData in song.chars) {
			collectCharAssets(charData.name ?? charData.id);
		}

		if (song.songData.gameplay?.events != null) {
			for (event in song.songData.gameplay.events) {
				if (event.name == 'Change Character') {
					var newChar:Null<String> = event.arguments != null ? Reflect.field(event.arguments, 'newCharacter') : null;
					if (newChar != null)
						collectCharAssets(newChar);
				}
			}
		}

		var noteSkin = song.noteSkin ?? 'default';
		collectNoteSkinAssets(noteSkin);
		collectSplashAssets(noteSkin);
		collectCountdownAssets(song.countdown ?? 'default', noteSkin);
		collectSongAudio(song, songFolder);
	}

	function collectSplashAssets(skinName:String) {
		var splashData:Null<NoteSkinData> = game.objects.sprites.notes.NoteSkins.read(skinName, 'splashes');
		if (splashData != null && splashData.props != null && splashData.props.path != null) {
			var folder = splashData.props.folder ?? 'game/noteskins/$skinName/splashes';
			enqueue(folder == '' ? splashData.props.path : '$folder/${splashData.props.path}');
		}
	}

	function collectCountdownAssets(countdownName:String, noteSkin:String) {
		var imageFolder = 'game/ui/countdown/$countdownName';
		var countData:core.json.game.objects.CountdownData = null;

		if (countdownName == 'default') {
			var fromSkin:core.json.game.objects.CountdownData = game.objects.sprites.notes.NoteSkins.read(noteSkin, 'countdown');
			if (fromSkin != null) {
				countData = fromSkin;
				var folder = game.objects.sprites.notes.NoteSkins.imageFolder(noteSkin, 'countdown');
				imageFolder = StringTools.endsWith(folder, '/') ? folder.substr(0, folder.length - 1) : folder;
			}
		}

		if (countData == null)
			countData = FormatJson.readJson(Paths.getPath('game/ui/countdown/$countdownName/$countdownName', 'json'));

		if (countData == null || countData.countdown == null)
			return;

		for (step in countData.countdown) {
			if (step?.props?.path != null)
				enqueue('$imageFolder/${step.props.path}');
		}
	}

	function collectSongAudio(song:SongConfig, songFolder:String) {
		Paths.currentSong = songFolder;

		enqueueAudio(Paths.getPath('Inst' + (song.instPrefix ?? ''), SONG_AUDIO));
		if (song.needVoices) {
			if (song.vocs == null) {
				enqueueAudio(Paths.getPath('Voices' + (song.vocPrefix ?? ''), SONG_AUDIO));
			} else {
				for (i in 0...song.chars.length) {
					var stem = i < song.vocs.length ? song.vocs[i] : null;
					if (stem == null || stem == '')
						continue;
					var name = stem;
					var resolved = Paths.getPath(name, SONG_AUDIO);
					while (resolved == null && name.lastIndexOf('-') > 0) {
						name = name.substr(0, name.lastIndexOf('-'));
						resolved = Paths.getPath(name, SONG_AUDIO);
					}
					enqueueAudio(resolved);
				}
			}
		}
	}

	function collectStageAssets(stageName:String) {
		var stageData:Null<StageData> = modding.vslice.VSliceStages.readStage(Paths.getPath('game/stages/$stageName/$stageName', 'json'));
		if (stageData == null || stageData.elements == null)
			return;

		for (el in stageData.elements) {
			if (el.props == null || el.props.path == null)
				continue;
			var folder:String;
			if (el.props.folder != null) {
				folder = el.props.folder;
			} else {
				folder = 'game/stages/$stageName';
			}
			enqueue(folder == '' ? el.props.path : '$folder/${el.props.path}');
		}
	}

	function collectCharAssets(charName:String) {
		var charData:Null<CharacterData> = modding.vslice.VSliceCharacters.readCharacter(Paths.getPath('game/characters/$charName/$charName', 'json'));
		if (charData == null || charData.render == null || charData.render.layers == null)
			return;

		for (layer in charData.render.layers) {
			var folder = layer.folder ?? 'game/characters';
			inline function inFolder(file:String)
				return folder == '' ? file : '$folder/$file';

			if (layer.path != null)
				enqueue(inFolder(layer.path));

			if (layer.anims == null)
				continue;
			for (anim in layer.anims) {
				var fp = getAnimFilePath(anim);
				if (fp != null && fp != layer.path)
					enqueue(inFolder(fp));
			}
		}

		enqueue('game/characters/$charName/$charName');
	}

	function collectNoteSkinAssets(skinName:String) {
		var noteSkinData:Null<NoteSkinData> = game.objects.sprites.notes.NoteSkins.read(skinName, 'strumnotes');
		if (noteSkinData != null && noteSkinData.props != null && noteSkinData.props.path != null) {
			var folder = noteSkinData.props.folder;
			enqueue(folder != null
				&& folder != '' ? '$folder/${noteSkinData.props.path}' : 'game/noteskins/$skinName/strumnotes/${noteSkinData.props.path}');
		}
	}

	static function getAnimFilePath(anim:core.json.extensions.SpriteData.AnimData):Null<String> {
		if (anim.filePath == null)
			return null;
		return (anim.filePath is String) ? cast anim.filePath : (cast anim.filePath : Array<Dynamic>)[0];
	}

	function loadNext() {
		while (loading < MAX_LOADING && (nextImage < queue.length || nextAudio < audioQueue.length)) {
			loading++;
			if (nextImage < queue.length)
				Paths.cacheAutoAsync(queue[nextImage++], _ -> onAssetLoaded());
			else
				loadAudio(audioQueue[nextAudio++]);
		}
	}

	function loadAudio(absPath:String) {
		sys.thread.Thread.create(function() {
			var oflSound:openfl.media.Sound = null;
			try {
				var buffer = lime.media.AudioBuffer.fromFile(absPath);
				oflSound = buffer != null ? openfl.media.Sound.fromAudioBuffer(buffer) : null;
			} catch (e:Dynamic) {
				Console.log('[LoadingState] could not load "$absPath": $e', true);
			}
			haxe.MainLoop.runInMainThread(function() {
				if (oflSound != null && !core.audio.Sound.streamedCache.exists(absPath))
					core.audio.Sound.streamedCache.set(absPath, oflSound);
				onAssetLoaded();
			});
		});
	}

	function onAssetLoaded() {
		loading--;
		loaded++;
		if (!destroyed)
			updateBar();
	}

	function updateBar() {
		var progress:Float = flixel.math.FlxMath.bound(loaded / Math.max(1, total), 0, 1);
		barTargetX = barStartX + bar.width * progress;
	}

	inline function isPrebuiltReady():Bool {
		return prebuiltInterface == null || prebuiltInterface.prebuilt;
	}

	function onAllLoaded() {
		if (done)
			return;
		done = true;

		#if HSCRIPT_ALLOWED
		script.call("onAllLoaded", []);
		#end

		new flixel.util.FlxTimer().start(0.1, (_) -> {
			flixel.tweens.FlxTween.tween(micStand, {alpha: 0}, 0.4);
			if (character != null)
				flixel.tweens.FlxTween.tween(character, {alpha: 0}, 0.4, {
					onComplete: _ -> launchState()
				});
		});
	}

	function launchState() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable("onLaunchPlayState", []))
			return;
		#end

		if (prebuiltState != null)
			MusicBeatState.switchState(() -> prebuiltState)
		else if (onStateReady != null)
			MusicBeatState.switchState(onStateReady);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		loadNext();

		#if HSCRIPT_ALLOWED
		if (script.hasScripts)
			script.call("onUpdate", [elapsed]);
		if (script.callCancellable("onUpdateCancel", [elapsed]))
			return;
		#end

		if (prebuiltInterface != null && !prebuiltInterface.prebuilt)
			prebuiltInterface.prebuildStep();

		var assetsReady:Bool = (loaded >= total);

		if (assetsReady && isPrebuiltReady() && !done)
			onAllLoaded();

		bar.x = InfiniteUtil.smoothLerpPrecision(bar.x, barTargetX, elapsed, 0.2);

		#if HSCRIPT_ALLOWED
		if (script.hasScripts)
			script.call("postUpdate", [elapsed]);
		#end
	}

	override public function destroy() {
		destroyed = true;
		super.destroy();
		character = null;
		micStand = null;
		prebuiltInterface = null;
	}
}

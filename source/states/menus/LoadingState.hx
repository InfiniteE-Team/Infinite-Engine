package states.menus;

import flixel.tweens.FlxTween;
import core.assets.FunkinSprite;
import core.json.song.SongData.SongConfig;
import core.json.objects.CharacterData;
import core.json.objects.StageData;
import core.json.objects.NoteSkinData;
import states.menus.objects.FunkinLoadingCharacter;
import core.json.menus.loading.LoadingCharacterData;

class LoadingState extends MusicBeatState {
	// config
	var songFolder:String;
	var curDifficulty:Int;

	var total:Int = 0;
	var loaded:Int = 0;
	var done:Bool = false;

	// assets Precached
	var queue:Array<String> = [];
	var audioQueue:Array<String> = [];

	public static final BAR_PAD:Int = 16;

	public var barTargetX:Float = 0;

	var barStartX:Float = 0;

	// loading more at once spikes the RAM -JloorDev
	static inline final MAX_LOADING:Int = 2;

	var loading:Int = 0;
	var nextImage:Int = 0;
	var nextAudio:Int = 0;
	var destroyed:Bool = false;

	var bar:Null<FunkinSprite> = null;
	var micStand:Null<FunkinSprite> = null;
	var character:Null<FunkinLoadingCharacter> = null;

	var dataList:Array<LoadingCharacterData> = [];

	var prebuiltState:game.PlayState = null;
	var isLoadingFinished:Bool = false;

	function startLoadingSong() {
		prebuiltState = new game.PlayState(songFolder, curDifficulty);
	}

	public function new(songFolder:String, curDifficulty:Int = 0) {
		super();
		this.songFolder = songFolder;
		this.curDifficulty = curDifficulty;

		bar = new FunkinSprite(0, 0, true);
		micStand = new FunkinSprite(0, 0, true);
		character = new FunkinLoadingCharacter();
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

		startLoadingSong();

		collectQueue();

		total = queue.length + audioQueue.length;
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

	function loadCharacterData():Void {
		var folder = core.assets.Library.findLib('images/menus/loading/characters');
		if (!sys.FileSystem.exists(folder) || !sys.FileSystem.isDirectory(folder))
			return;

		for (file in sys.FileSystem.readDirectory(folder)) {
			if (!sys.FileSystem.isDirectory('$folder/$file'))
				continue;
			var data:LoadingCharacterData = FormatJson.readJson('$folder/$file/$file.json');
			if (data != null)
				dataList.push(data);
		}
	}

	public function getCharacter():Void {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable("onGetCharacterCancel", []))
			return;
		#end
		final folder = core.assets.Library.findLib('images/menus/loading/characters');
		var charNames:Array<String> = [];

		if (sys.FileSystem.exists(folder) && sys.FileSystem.isDirectory(folder)) {
			for (file in sys.FileSystem.readDirectory(folder)) {
				charNames.push(file);
			}
		}

		if (charNames.length == 0)
			return;
		var weights:Array<Float> = [];

		for (data in dataList) {
			weights.push(data.weight);
		}
		var characterData:LoadingCharacterData = FlxG.random.getObject(dataList, weights);
		var idx:Int = dataList.indexOf(characterData);
		var characterId:String = charNames[idx];
		character.loadCharacter(characterData, Paths.getPath('menus/loading/characters/$characterId/$characterId', 'animated'));
		add(character);

		#if HSCRIPT_ALLOWED
		script.call("postGetCharacter", []);
		#end
	}

	function collectQueue() {
		var song:Null<SongConfig> = new SongConfig();
		song.configSong(songFolder, core.rhythm.DiffsUtils.difficulties[curDifficulty]);

		if (song.songData == null)
			return;

		var stageId = song.stage ?? 'stage';
		collectStageAssets(stageId);

		for (charData in song.chars) {
			var charName = charData.name ?? charData.id;
			collectCharAssets(charName);
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

		collectNoteSkinAssets(song.noteSkin ?? 'default');
		collectAudioAssets(song);
	}

	function collectAudioAssets(song:SongConfig) {
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

	function enqueueAudio(path:String) {
		if (path == null)
			return;
		var abs = sys.FileSystem.absolutePath(path);
		if (core.rhythm.audio.Sound.isStreamable(abs))
			return;
		if (!audioQueue.contains(abs) && !core.rhythm.audio.Sound.streamedCache.exists(abs))
			audioQueue.push(abs);
	}

	function collectStageAssets(stageName:String) {
		var stageData:Null<StageData> = modding.vslice.VSliceStages.readStage(Paths.getPath('data/stages/$stageName', 'json'));
		if (stageData == null || stageData.elements == null)
			return;

		for (el in stageData.elements) {
			if (el.props == null || el.props.path == null)
				continue;
			var folder = el.props.folder ?? 'game/stages/$stageName';
			enqueue(folder == '' ? el.props.path : '$folder/${el.props.path}');
		}
	}

	function collectCharAssets(charName:String) {
		var charData:Null<CharacterData> = modding.vslice.VSliceCharacters.readCharacter(Paths.getPath('data/characters/$charName', 'json'));
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
	}

	function collectNoteSkinAssets(skinName:String) {
		var noteSkinData:Null<NoteSkinData> = game.objects.sprites.notes.NoteSkins.read(skinName, 'strumnotes');
		if (noteSkinData != null && noteSkinData.props != null && noteSkinData.props.path != null)
			enqueue(noteSkinData.props.folder != null ? noteSkinData.props.path : 'game/noteskins/$skinName/strumnotes/${noteSkinData.props.path}');
	}

	inline function enqueue(path:String) {
		if (!queue.contains(path))
			queue.push(path);
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
				if (oflSound != null && !core.rhythm.audio.Sound.streamedCache.exists(absPath))
					core.rhythm.audio.Sound.streamedCache.set(absPath, oflSound);
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

	function onAllLoaded() {
		if (done)
			return;
		done = true;

		#if HSCRIPT_ALLOWED
		script.call("onAllLoaded", []);
		#end

		new flixel.util.FlxTimer().start(0.1, (_) -> {
			FlxTween.tween(micStand, {alpha: 0}, 0.4);
			if (character != null)
				FlxTween.tween(character, {alpha: 0}, 0.4, {
					onComplete: _ -> {
						launchPlayState();
					}
				});
		});
	}

	function launchPlayState() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable("onLaunchPlayState", []))
			return;
		#end

		MusicBeatState.switchState(() -> prebuiltState);
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

		if (prebuiltState != null && !prebuiltState.prebuilt) {
			prebuiltState.prebuildStep();
		}

		var assetsReady:Bool = (loaded >= total);
		var playStateReady:Bool = (prebuiltState != null && prebuiltState.prebuilt);

		if (assetsReady && playStateReady && !done) {
			onAllLoaded();
		}

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
	}
}

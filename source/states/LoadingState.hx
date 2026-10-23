package states;

import game.PlayState;
import core.json.song.SongData.SongConfig;
import core.json.objects.CharacterData;
import core.json.objects.StageData;
import core.json.objects.NoteSkinData;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class LoadingState extends MusicBeatState {
	// config
	var songFolder:String;
	var _curDifficulty:Int;

	var _total:Int = 0;
	var _loaded:Int = 0;
	var _done:Bool = false;
	var _readyToGo:Bool = false;

	// assets Precached
	var _queue:Array<String> = [];
	var _audioQueue:Array<String> = [];

	var _bg:FlxSprite;
	var _bar:FlxBar;
	var _barBg:FlxSprite;
	var _label:FlxText;
	var _songLabel:FlxText;

	static inline var BAR_W:Int = 640;
	static inline var BAR_H:Int = 10;

	public function new(songFolder:String, curDifficulty:Int = 0) {
		super();
		this.songFolder = songFolder;
		_curDifficulty = curDifficulty;
	}

	override public function create() {
		super.create();

		#if HSCRIPT_ALLOWED
		initScript();
		script.executeAll();
		script.call("onCreate", []);
		#end

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		buildUI();
		collectQueue();

		if (_queue.length == 0) {
			launchPlayState();
			return;
		}

		_total = _queue.length + _audioQueue.length;
		dispatchQueue();
		dispatchAudioQueue();
	}

	function buildUI() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable("onCreateCancel", []))
			return;
		#end

		_bg = new FlxSprite().loadGraphic(Paths.getPath('menus/menuBG2', 'image'));
		_bg.screenCenter();
		_bg.antialiasing = SaveData.data.antialiasing;
		_bg.scrollFactor.set(0, 0);
		add(_bg);

		#if HSCRIPT_ALLOWED
		script.call("postBGCreate", []);
		#end

		_songLabel = new FlxText(0, FlxG.height * 0.85, FlxG.width, SongConfig.getSongName(songFolder.toUpperCase()));
		_songLabel.setFormat(Paths.getPath('Funkin.otf', 'font'), 28, FlxColor.WHITE, CENTER);
		_songLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		_songLabel.alpha = 0.9;
		add(_songLabel);

		_barBg = new FlxSprite((FlxG.width - BAR_W) / 2, FlxG.height * 0.9).makeGraphic(BAR_W, BAR_H, 0xFF333333);
		add(_barBg);

		_bar = new FlxBar(_barBg.x, _barBg.y, LEFT_TO_RIGHT, BAR_W, BAR_H, this, '_loaded', 0, 1);
		_bar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.WHITE);
		add(_bar);

		_label = new FlxText(0, _barBg.y + BAR_H + 14, FlxG.width, "Loading...");
		_label.setFormat(null, 14, 0xFF888888, CENTER);
		add(_label);

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end
	}

	function collectQueue() {
		var song:SongConfig = new SongConfig();
		song.configSong(songFolder, core.rhythm.DiffsUtils.difficulties[_curDifficulty]);

		if (song.songData == null) {
			launchPlayState();
			return;
		}

		var stageId = song.stage ?? 'stage';
		collectStageAssets(stageId);

		for (charData in song.chars) {
			var charName = charData.name ?? charData.id;
			collectCharAssets(charName);
		}

		if (song.songData.gameplay?.events != null) {
			for (event in song.songData.gameplay.events) {
				if (event.name == 'Change Character') {
					var newChar:String = event.arguments != null ? Reflect.field(event.arguments, 'newCharacter') : null;
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

		// Voces
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
		if (!_audioQueue.contains(abs) && !core.rhythm.audio.Sound.streamedCache.exists(abs))
			_audioQueue.push(abs);
	}

	function dispatchAudioQueue() {
		for (absPath in _audioQueue) {
			sys.thread.Thread.create(function() {
				#if lime_cffi
				var buffer = lime.media.AudioBuffer.fromFile(absPath);
				var oflSound = buffer != null ? openfl.media.Sound.fromAudioBuffer(buffer) : null;
				#else
				var oflSound = openfl.media.Sound.fromFile(absPath);
				#end

				haxe.MainLoop.runInMainThread(function() {
					if (oflSound != null && !core.rhythm.audio.Sound.streamedCache.exists(absPath))
						core.rhythm.audio.Sound.streamedCache.set(absPath, oflSound);

					_loaded++;
					updateBar();
					if (_loaded >= _total && !_done) {
						_done = true;
						onAllLoaded();
					}
				});
			});
		}
	}

	function collectStageAssets(stageName:String) {
		var stageData:StageData = modding.vslice.VSliceStages.readStage(Paths.getPath('data/stages/$stageName', 'json'));
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
		var charData:CharacterData = modding.vslice.VSliceCharacters.readCharacter(Paths.getPath('data/characters/$charName', 'json'));
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
		var noteSkinData:NoteSkinData = game.objects.sprites.notes.NoteSkins.read(skinName, 'strumnotes');
		if (noteSkinData != null && noteSkinData.props != null && noteSkinData.props.path != null)
			enqueue(noteSkinData.props.folder != null ? noteSkinData.props.path : 'game/noteskins/$skinName/strumnotes/${noteSkinData.props.path}');
	}

	inline function enqueue(path:String) {
		if (!_queue.contains(path))
			_queue.push(path);
	}

	static function getAnimFilePath(anim:core.json.extensions.SpriteData.AnimData):Null<String> {
		if (anim.filePath == null)
			return null;
		return (anim.filePath is String) ? cast anim.filePath : (cast anim.filePath : Array<Dynamic>)[0];
	}

	function dispatchQueue() {
		for (path in _queue) {
			Paths.cacheAutoAsync(path, function(_) {
				_loaded++;
				updateBar();

				if (_loaded >= _total && !_done) {
					_done = true;
					onAllLoaded();
				}
			});
		}
	}

	var _barValue(get, never):Float;

	inline function get__barValue():Float
		return _total > 0 ? (_loaded / _total) : 0.0;

	function updateBar() {
		_bar.setRange(0, _total);
		_bar.setParent(this, '_loaded', false, 0, _total);

		var pct = Std.int((_loaded / _total) * 100);
		_label.text = '$pct%   (${_loaded} / ${_total})';
	}

	// end
	function onAllLoaded() {
		_label.text = "¡Done!";

		FlxTween.tween(_bg, {alpha: 0}, 1, {
			ease: FlxEase.quadIn,
			onComplete: function(_) {
				launchPlayState();
			}
		});
		FlxTween.tween(_songLabel, {alpha: 0}, 0.25);
		FlxTween.tween(_bar, {alpha: 0}, 0.25);
		FlxTween.tween(_barBg, {alpha: 0}, 0.25);
		FlxTween.tween(_label, {alpha: 0}, 0.2);
	}

	function launchPlayState() {
		#if HSCRIPT_ALLOWED
		if (script.callCancellable("onLaunchPlayState", []))
			return;
		#end

		if (_readyToGo)
			return;
		_readyToGo = true;

		MusicBeatState.switchState(() -> new PlayState(songFolder, _curDifficulty));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		if (script.hasScripts)
			script.call("onUpdate", [elapsed]);
		if (script.callCancellable("onUpdateCancel", [elapsed]))
			return;
		#end

		var t = haxe.Timer.stamp();

		#if HSCRIPT_ALLOWED
		if (script.hasScripts)
			script.call("postUpdate", [elapsed]);
		#end
	}

	override public function destroy() {
		super.destroy();

		_bg = null;
		_bar = null;
		_barBg = null;
		_label = null;
		_songLabel = null;
	}
}

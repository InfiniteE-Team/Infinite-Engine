package states;

import core.assets.Paths;
import core.assets.FunkinSprite;
import core.json.song.SongData.SongConfig;
import core.json.objects.CharacterData;
import core.json.objects.StageData;
import core.json.objects.NoteSkinData;
import utils.UtilsData;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class LoadingState extends MusicBeatState {
	// config
	var _curSong:String;
	var _curDifficulty:Int;

	var _total:Int = 0;
	var _loaded:Int = 0;
	var _done:Bool = false;
	var _readyToGo:Bool = false;

	// assets Precached
	var _queue:Array<String> = [];

	var _bg:FlxSprite;
	var _bar:FlxBar;
	var _barBg:FlxSprite;
	var _label:FlxText;
	var _songLabel:FlxText;
	var _iconAnim:FlxSprite;

	static inline var BAR_W:Int = 640;
	static inline var BAR_H:Int = 10;

	public function new(curSong:String, curDifficulty:Int = 0) {
		super();
		_curSong = curSong;
		_curDifficulty = curDifficulty;
	}

	override public function create() {
		super.create();

		buildUI();
		collectQueue();

		if (_queue.length == 0) {
			launchPlayState();
			return;
		}

		_total = _queue.length;
		dispatchQueue();
	}

	function buildUI() {
		_bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(_bg);

		_iconAnim = new FlxSprite(FlxG.width * 0.5 - 20, FlxG.height * 0.38);
		_iconAnim.makeGraphic(40, 40, 0xFFFFFFFF);
		_iconAnim.alpha = 0.15;
		add(_iconAnim);

		_songLabel = new FlxText(0, FlxG.height * 0.45, FlxG.width, _curSong.toUpperCase());
		_songLabel.setFormat(null, 28, FlxColor.WHITE, CENTER);
		_songLabel.alpha = 0.9;
		add(_songLabel);

		_barBg = new FlxSprite((FlxG.width - BAR_W) / 2, FlxG.height * 0.56).makeGraphic(BAR_W, BAR_H, 0xFF333333);
		add(_barBg);

		_bar = new FlxBar(_barBg.x, _barBg.y, LEFT_TO_RIGHT, BAR_W, BAR_H, this, '_loaded', 0, 1);
		_bar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.WHITE);
		add(_bar);

		_label = new FlxText(0, _barBg.y + BAR_H + 14, FlxG.width, "Loading...");
		_label.setFormat(null, 14, 0xFF888888, CENTER);
		add(_label);
	}

	function collectQueue() {
		var song:SongConfig = new SongConfig();
		song.configSong(_curSong, _curSong);

		var stageId = song.stage ?? 'stage';
		collectStageAssets(stageId);

		for (charData in song.chars) {
			var charName = charData.name ?? charData.id;
			collectCharAssets(charName);
		}

		collectNoteSkinAssets(song.noteSkin ?? 'default');
	}

	function collectStageAssets(stageName:String) {
		var stageData:StageData = UtilsData.readJson(Paths.getPath('data/stages/$stageName', 'json'));
		if (stageData == null)
			return;

		for (el in stageData.elements) {
			if (el.props == null || el.props.path == null)
				continue;
			enqueue('game/stages/$stageName/${el.props.path}');
		}
	}

	function collectCharAssets(charName:String) {
		var charData:CharacterData = UtilsData.readJson(Paths.getPath('data/characters/$charName', 'json'));
		if (charData == null)
			return;

		for (layer in charData.render.layers) {
			if (layer.path != null)
				enqueue('game/characters/${layer.path}');
		}

		if (charData.render.layers != null) {
			for (layer in charData.render.layers) {
				if (layer.anims == null)
					continue;
				for (anim in layer.anims) {
					var fp = getAnimFilePath(anim);
					if (fp != null && fp != layer.path)
						enqueue('game/characters/$fp');
				}
			}
		}
	}

	function collectNoteSkinAssets(skinName:String) {
		var noteSkinData:NoteSkinData = UtilsData.readJson(Paths.getPath('data/noteskins/$skinName/strumnotes', "json"));
		if (noteSkinData != null && noteSkinData.props != null && noteSkinData.props.path != null)
			enqueue('game/noteskins/$skinName/strumnotes/${noteSkinData.props.path}');
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

		FlxTween.tween(_bg, {alpha: 0}, 0.35, {ease: FlxEase.quadIn});
		FlxTween.tween(_songLabel, {alpha: 0}, 0.25);
		FlxTween.tween(_bar, {alpha: 0}, 0.25);
		FlxTween.tween(_barBg, {alpha: 0}, 0.25);
		FlxTween.tween(_label, {alpha: 0}, 0.2);

		FlxTween.tween(_iconAnim, {alpha: 0}, 0.35, {
			ease: FlxEase.quadIn,
			onComplete: function(_) {
				launchPlayState();
			}
		});
	}

	function launchPlayState() {
		if (_readyToGo)
			return;
		_readyToGo = true;

		var ps = new game.PlayState();
		ps.curSong = _curSong;
		ps.curDifficulty = _curDifficulty;
		MusicBeatState.switchState(ps);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var t = haxe.Timer.stamp();
		_iconAnim.scale.set(1.0 + 0.06 * Math.sin(t * 3.0), 1.0 + 0.06 * Math.sin(t * 3.0));
		_iconAnim.updateHitbox();
	}
}

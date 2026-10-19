package funkin.play;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;

// the slice of V-Slice's PlayState.instance that stage scripts read, backed by the engine PlayState -JloorDev
@:keep
class PlayState {
	public static var instance:PlayState;

	public var currentStage:funkin.play.stage.Stage;
	public var currentSong:{id:String};

	public var camGame(get, never):FlxCamera;
	public var camHUD(get, never):FlxCamera;
	public var camCutscene(get, never):FlxCamera;
	public var cameraFollowPoint(get, never):FlxObject;
	public var health(get, set):Float;
	public var isBotPlayMode(get, never):Bool;
	public var stageZoom(get, set):Float;
	public var iconP1(get, never):Dynamic;
	public var iconP2(get, never):Dynamic;
	public var healthBar(get, never):Dynamic;
	public var healthBarBG(get, never):Dynamic;
	public var scoreText(get, never):Dynamic;
	public var isGamePaused(get, never):Bool;
	public var isGameOverState(get, never):Bool;
	public var cameraZoomRate(get, set):Float;
	public var cameraBopMultiplier(get, set):Float;
	public var currentCameraZoom(get, set):Float;
	public var defaultHUDCameraZoom:Float = 1.0;

	public var currentSongScript:funkin.play.song.Song;
	public var isInCutscene:Bool = false;
	public var isInCountdown:Bool = false;
	public var mayPauseGame:Bool = true;
	public var isChartingMode:Bool = false;
	public var isMinimalMode:Bool = false;
	public var justUnpaused:Bool = false;
	public var playbackRate:Float = 1.0;
	public var startTimestamp:Float = 0;
	public var currentVariation:String = 'default';
	public var currentDifficulty:String = 'normal';
	public var comboPopUps:Dynamic = {offsets: [0, 0]};
	public var controls:ScriptControls = new ScriptControls();
	public var playerStrumline:funkin.play.notes.Strumline = new funkin.play.notes.Strumline(true);
	public var opponentStrumline:funkin.play.notes.Strumline = new funkin.play.notes.Strumline(false);

	public function new(stage:funkin.play.stage.Stage, songId:String) {
		currentStage = stage;
		currentSong = {id: songId};
		var diffs = core.rhythm.DiffsUtils.difficulties;
		var diff = engine()?.curDifficulty ?? 0;
		if (diffs != null && diff < diffs.length)
			currentDifficulty = diffs[diff];
	}

	inline function engine():game.PlayState
		return game.PlayState.instance;

	function get_camGame():FlxCamera
		return engine()?.camGame;

	function get_camHUD():FlxCamera
		return engine()?.camHUD;

	function get_camCutscene():FlxCamera
		return engine()?.camOther;

	function get_cameraFollowPoint():FlxObject
		return engine()?.cameraController?.camPoint;

	function get_health():Float
		return engine()?.playStateConfig?.health ?? 0;

	function set_health(v:Float):Float {
		if (engine()?.playStateConfig != null)
			engine().playStateConfig.health = v;
		return v;
	}

	function get_isBotPlayMode():Bool
		return SaveData.data.botplay == true;

	function get_stageZoom():Float
		return engine()?.cameraController?.stageZoom ?? 1.0;

	function set_stageZoom(v:Float):Float {
		if (engine()?.cameraController != null)
			engine().cameraController.stageZoom = v;
		return v;
	}

	function get_iconP1():Dynamic
		return engine()?.controllerHUD?.iconP1;

	function get_iconP2():Dynamic
		return engine()?.controllerHUD?.iconP2;

	function get_healthBar():Dynamic
		return engine()?.controllerHUD?.healthBar;

	function get_healthBarBG():Dynamic
		return engine()?.controllerHUD?.healthBarBG;

	function get_scoreText():Dynamic
		return engine()?.controllerHUD?.scoreText;

	function get_isGamePaused():Bool
		return engine()?.paused == true;

	function get_isGameOverState():Bool
		return GameOverSubState.instance != null;

	function get_cameraZoomRate():Float
		return engine()?.cameraController?.bopEvery ?? 4;

	function set_cameraZoomRate(v:Float):Float {
		if (engine()?.cameraController != null)
			engine().cameraController.bopEvery = Std.int(v);
		return v;
	}

	function get_cameraBopMultiplier():Float {
		var cam = engine()?.cameraController;
		return cam != null && cam.defaultZoom != 0 ? cam.camGame.zoom / cam.defaultZoom : 1.0;
	}

	function set_cameraBopMultiplier(v:Float):Float {
		var cam = engine()?.cameraController;
		if (cam != null)
			cam.camGame.zoom = cam.defaultZoom * v;
		return v;
	}

	function get_currentCameraZoom():Float
		return engine()?.cameraController?.defaultZoom ?? 1.0;

	function set_currentCameraZoom(v:Float):Float {
		if (engine()?.cameraController != null)
			engine().cameraController.defaultZoom = v;
		return v;
	}

	public function tweenCameraZoom(?zoom:Float, ?duration:Float, ?direct:Bool, ?ease:Dynamic):Void {
		var cam = engine()?.cameraController;
		if (cam == null)
			return;
		var target = zoom ?? 1.0;
		if (direct != true)
			target *= cam.stageZoom;
		cam.zoomTo(target, duration ?? 0, ease ?? (duration != null && duration > 0 ? flixel.tweens.FlxEase.linear : null));
	}

	public function resetCameraZoom():Void
		tweenCameraZoom(1, 0, false);

	public function tweenCameraToPosition(?x:Float, ?y:Float, ?duration:Float, ?ease:Dynamic):Void {
		var cam = engine()?.cameraController;
		if (cam != null)
			cam.focusOn(null, x ?? cam.camPoint.x, y ?? cam.camPoint.y, duration ?? 0, ease ?? flixel.tweens.FlxEase.linear, duration == null || duration <= 0);
	}

	public function tweenCameraToFollowPoint(?duration:Float, ?ease:Dynamic):Void {}

	public function cancelCameraFollowTween():Void {}

	public function cancelCameraZoomTween():Void {}

	public function startCountdown():Void
		engine()?.resumeVSliceCountdown();

	public function startSong():Void {}

	public function endSong(?rightGoddamnNow:Bool, ?force:Bool):Void
		engine()?.endSong();

	public function add(obj:FlxBasic):FlxBasic {
		if (engine() != null)
			engine().add(obj);
		else if (currentStage != null)
			currentStage.add(obj);
		return obj;
	}

	public function remove(obj:FlxBasic):FlxBasic {
		if (engine() != null)
			engine().remove(obj, true);
		return obj;
	}
}

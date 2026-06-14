package core;
import flixel.util.typeLimit.NextState.InitialState;
import flixel.FlxGame;

class Game extends FlxGame {
	public function new(width:Int, height:Int, initialState:InitialState, framerate:Int) {
		super(width, height, initialState, framerate, framerate, true, false);
		_customSoundTray = cast core.system.SoundTray;
	}
}

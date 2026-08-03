package core;
import flixel.util.typeLimit.NextState.InitialState;
import flixel.FlxGame;

class Game extends FlxGame {
	public function new(initialState:InitialState) {
		super(1280, 720, initialState, 60, 60, true, false);
		_customSoundTray = cast core.ui.SoundTray;
		
	}
}

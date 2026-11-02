package core;
import flixel.util.typeLimit.NextState.InitialState;

class Game extends flixel.FlxGame {
	public function new(initialState:InitialState) {
		super(1280, 720, initialState, 60, 60, true, false);
		_customSoundTray = cast core.ui.SoundTray;

		#if desktop
		core.api.DesktopAPI.init();
		#end
	}
}

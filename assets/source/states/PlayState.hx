import game.PlayStateConfig;
import flixel.util.FlxTimer;

function postCreate() {
	lime.app.Application.current.window.title = "Infinite Engine - Song: " + curSong;
}

function onUpdate(elapsed) {
	if (Controls.ACCEPT)
		pauseMenu();

	if (FlxG.keys.justPressed.R && !startCount)
		isDeath();
}

function postEndSong() {
	new FlxTimer().start(2, (_) -> {
		if (!PlayStateConfig.isStoryMode)
			MusicBeatState.switchState(() -> new states.menus.FreeplayState());
		else
			ScriptClass.switchState('StoryMenuState');
	});
}

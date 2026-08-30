import game.PlayStateConfig;

function postCreate() {
	lime.app.Application.current.window.title = "Infinite Engine - Song: " + curSong;
}

function onUpdate(elapsed) {
	if (Controls.ACCEPT)
		pauseMenu();

	if (FlxG.keys.justPressed.SEVEN) {
		MusicBeatState.switchState(() -> new modding.editors.GameplayEditor(SONG));
	}

	if (FlxG.keys.justPressed.R && !startCount)
		isDeath();
}

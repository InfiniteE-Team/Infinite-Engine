import game.PlayStateConfig;

function postCreate() {
	lime.app.Application.current.window.title = modding.mods.ModData.ModConfig.modData?.name + " - Song: " + curSong ?? "Infinite Engine" + " - Song: " + curSong;
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

function onDestroy() {
	lime.app.Application.current.window.title = modding.mods.ModData.ModConfig.modData?.name ?? "Infinite Engine";
}

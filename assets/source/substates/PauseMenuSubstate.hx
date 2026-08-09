import game.PlayStateConfig;

function ExitMenu() {
	if (!PlayStateConfig.isStoryMode)
		MusicBeatState.switchState(() -> new states.menus.FreeplayState());
	else
		MusicBeatState.switchState(() -> new states.menus.StoryMenuState());
}
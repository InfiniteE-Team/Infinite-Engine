import game.PlayStateConfig;

function ExitMenu() {
	if (!PlayStateConfig.isStoryMode)
		MusicBeatState.switchState(() -> new states.menus.FreeplayState(), 'default');
	else
		MusicBeatState.switchState(() -> new states.menus.StoryMenuState(), 'default');
}
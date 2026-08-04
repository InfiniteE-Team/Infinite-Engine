import game.PlayStateConfig;

function onBack() {
	if (!PlayStateConfig.isStoryMode)
		MusicBeatState.switchState(() -> new states.menus.FreeplayState());
}

import game.PlayStateConfig;

function onBack() {
	if (!PlayStateConfig.isStoryMode)
		ScriptClass.switchState('FreeplayState');
}

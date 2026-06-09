import core.scripting.ScriptedState;

function onUpdate(elapsed)
{
    if (FlxG.keys.justPressed.ENTER)
        pauseMenu();
}

function onPauseMenu()
{
    ScriptedState.openSubstate('PauseMenu');
}

/*
function onFocusLost()
{
    if (paused) {
        persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		FlxG.sound.pause();
		if (gameAudio.inst != null)
			gameAudio.inst.pause();
		if (gameAudio.vocals != null)
			gameAudio.vocals.pause();
    }
}*/
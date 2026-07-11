
function onCreate()
{
	curSong = 'fresh';
}

function postCreate()
{
	lime.app.Application.current.window.title = "Infinite Engine - Song: " + curSong;
}

function onUpdate(elapsed)
{
    if (FlxG.keys.justPressed.ENTER)
        pauseMenu();
}
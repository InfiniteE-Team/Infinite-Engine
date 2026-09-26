import game.PlayStateConfig;

function postCreate() {
	var titleName:String = modding.mods.ModData.ModConfig.modData?.name;
	if (modding.mods.ModData.ModConfig.modData?.name == null)
		titleName = "Infinite Engine";

	lime.app.Application.current.window.title = titleName + " - Song: " + curSong;
}

function onUpdate(elapsed) {
	if (Controls.ACCEPT)
		pauseMenu();

	if (Controls.GAME_DEATH && !startCount)
		isDeath();
}

function onDestroy() {
	lime.app.Application.current.window.title = modding.mods.ModData.ModConfig.modData?.name ?? "Infinite Engine";
}

var videoSprite:VideoSprite;

function postCreate() {
	if (core.rhythm.DiffsUtils.difficulties[curDifficulty].toUpperCase() == 'ERECT')
		return;

	videoSprite = new VideoSprite(0, 0, Paths.getPath('baki meme', 'videos', false));
	videoSprite.play();
	add(videoSprite);
}

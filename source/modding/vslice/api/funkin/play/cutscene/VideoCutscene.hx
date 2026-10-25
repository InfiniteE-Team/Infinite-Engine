package funkin.play.cutscene;

// VideoCutscenes for Cutscenes V-Slice

@:keep
class VideoCutscene extends game.objects.cutscenes.Cutscene {
	public static function play(path:String, ?cutsceneType:CutsceneType = STARTING):Void {
		var cutscene = new VideoCutscene();
		cutscene.onComplete = () -> onCutsceneFinish(cutsceneType);
		cutscene.playVideo(path);
	}

	public function playVideo(path:String):Void {
		#if VIDEO_ALLOWED
		isEnding = false;
		video = new game.objects.cutscenes.SafeVideoSprite();
		video.scrollFactor.set(0, 0);

		video.bitmap.onFormatSetup.add(() -> {
			if (video?.bitmap?.bitmapData == null)
				return;
			var d = video.bitmap.bitmapData;
			var s = Math.min(FlxG.width / d.width, FlxG.height / d.height);
			video.setGraphicSize(d.width * s, d.height * s);
			video.updateHitbox();
			video.screenCenter();
		});

		video.bitmap.onEndReached.add(() -> {
			skip();
		});

		if (!video.load(sys.FileSystem.fullPath(path))) {
			video.destroy();
			video = null;
			return;
		}

		active = true;
		var ps = game.PlayState.instance;
		ps.isInCutscene = true;
		if (ps.cutscene != null && ps.cutscene.active)
			ps.cutscene.destroy();
		ps.cutscene = this;

		var fnkPs = funkin.play.PlayState.instance;
		if (fnkPs != null) {
			fnkPs.isInCutscene = true;
			fnkPs.isInCountdown = false;
		}
		video.cameras = [ps.camOther];
		ps.add(video);
		video.play();
		#end
	}

	static function onCutsceneFinish(cutsceneType:CutsceneType):Void {
		switch (cutsceneType) {
			case CutsceneType.STARTING:
				funkin.play.PlayState.instance.startCountdown();
			case CutsceneType.ENDING:
				funkin.play.PlayState.instance.endSong(true); // true = right goddamn now
			case CutsceneType.MIDSONG:
				// Do nothing.
				// throw "Not implemented!";
		}
	}
}

enum CutsceneType {
	STARTING; // The default cutscene type. Starts the countdown after the video is done.
	MIDSONG; // Does nothing.
	ENDING; // Ends the song after the video is done.
}

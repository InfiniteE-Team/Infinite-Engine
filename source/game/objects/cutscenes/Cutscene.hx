package game.objects.cutscenes;

import flixel.tweens.FlxTween;

class Cutscene {
	public var active(default, null):Bool = false;

	#if VIDEO_ALLOWED
	var video:game.objects.cutscenes.SafeVideoSprite;
	#end

	var isEnding:Bool = false;

	public var onComplete:Void->Void;

	public function new() {}

	public function tryPlay(songFolder:String, slot:String, onComplete:Void->Void):Bool {
		#if VIDEO_ALLOWED
		this.onComplete = onComplete;
		isEnding = false;
		var path = resolve(songFolder, slot);
		if (path == null)
			return false;

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
			return false;
		}

		active = true;
		var ps = PlayState.instance;
		ps.isInCutscene = true;
		video.cameras = [ps.camOther];
		ps.add(video);
		video.play();
		return true;
		#else
		return false;
		#end
	}

	public function skip():Void {
		#if VIDEO_ALLOWED
		if (video != null && active && !isEnding) {
			isEnding = true;
			var cb = onComplete;

			FlxTween.tween(video, {alpha: 0}, 0.5, {
				onComplete: function(twn:FlxTween) {
					destroy();
					PlayState.instance.isInCutscene = false;
					if (cb != null)
						cb();
				}
			});
		}
		#end
	}

	public function pause():Void {
		#if VIDEO_ALLOWED
		if (!isEnding)
			video?.pause();
		#end
	}

	public function resume():Void {
		#if VIDEO_ALLOWED
		if (!isEnding)
			video?.resume();
		#end
	}

	public function destroy():Void {
		#if VIDEO_ALLOWED
		if (video != null) {
			PlayState.instance?.remove(video, true);
			video.stop();
			video.destroy();
			video = null;
		}
		#end
		active = false;
		isEnding = false;
	}

	static function resolve(songFolder:String, slot:String):Null<String> {
		var local = core.assets.Library.findLib('songs/$songFolder/videos/$slot.mp4');
		if (local != null)
			return local;

		var global = core.assets.Paths.getPath('$songFolder/$slot', core.enums.AssetType.VIDEOS);
		if (global != null)
			return global;

		if (slot == 'intro') {
			var bare = core.assets.Paths.getPath(songFolder, core.enums.AssetType.VIDEOS);
			if (bare != null)
				return bare;
		}

		return null;
	}
}

package game.controllers.events;

import core.json.song.SongData.EventsData;

// videos the chart plays with "Play Video": loaded when the song loads, played on their event, paused with the song -JloorDev
class SongVideos {
	#if VIDEO_ALLOWED
	var ready:Map<String, Array<states.cutscenes.SafeVideoSprite>> = new Map();
	var playing:Array<states.cutscenes.SafeVideoSprite> = [];
	#end

	public function new() {}

	public function preload(events:Array<EventsData>):Void {
		#if VIDEO_ALLOWED
		for (e in events)
			if (e.name == 'Play Video' && e.arguments?.video != null)
				prepare(Std.string(e.arguments.video));
		#end
	}

	public function play(name:String, camera:String):Bool {
		#if VIDEO_ALLOWED
		var list = ready.get(name);
		var video = list != null && list.length > 0 ? list.shift() : prepare(name, false);
		if (video == null)
			return false;

		var ps = PlayState.instance;
		video.cameras = [switch (camera) {
			case 'game': ps.camGame;
			case 'hud': ps.camHUD;
			default: ps.camOther;
		}];
		video.visible = true;
		ps.add(video);
		playing.push(video);
		video.play();
		return true;
		#else
		Console.log('[SongVideos] this build has no video support', true);
		return false;
		#end
	}

	public function pause():Void {
		#if VIDEO_ALLOWED
		for (v in playing)
			v.pause();
		#end
	}

	public function resume():Void {
		#if VIDEO_ALLOWED
		for (v in playing)
			v.resume();
		#end
	}

	public function destroy():Void {
		#if VIDEO_ALLOWED
		for (v in playing)
			finish(v);
		for (list in ready)
			for (v in list)
				v.destroy();
		playing = [];
		ready = new Map();
		#end
	}

	#if VIDEO_ALLOWED
	function prepare(name:String, keep:Bool = true):Null<states.cutscenes.SafeVideoSprite> {
		var path = Paths.getPath(name, 'videos') ?? Paths.getPath('videos/$name', 'videos');
		if (path == null) {
			Console.log('[SongVideos] video "$name" not found in videos/', true);
			return null;
		}
		var video = new states.cutscenes.SafeVideoSprite();
		video.scrollFactor.set(0, 0);
		video.visible = false;
		video.bitmap.onFormatSetup.add(() -> {
			if (video.bitmap?.bitmapData == null)
				return;
			var data = video.bitmap.bitmapData;
			var scale = Math.min(FlxG.width / data.width, FlxG.height / data.height);
			video.setGraphicSize(data.width * scale, data.height * scale);
			video.updateHitbox();
			video.screenCenter();
		});
		video.bitmap.onEndReached.add(() -> finish(video));
		if (!video.load(sys.FileSystem.fullPath(path))) {
			Console.log('[SongVideos] could not load "$path"', true);
			video.destroy();
			return null;
		}
		if (keep) {
			if (!ready.exists(name))
				ready.set(name, []);
			ready.get(name).push(video);
		}
		return video;
	}

	function finish(video:states.cutscenes.SafeVideoSprite):Void {
		playing.remove(video);
		PlayState.instance?.remove(video, true);
		video.stop();
		video.destroy();
	}
	#end
}

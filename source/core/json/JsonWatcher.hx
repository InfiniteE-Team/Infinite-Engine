package core.json;
import sys.FileSystem;

class JsonWatcher {
	static var paths:Array<String> = [];
	static var mtimes:Array<Float> = [];
	static var callbacks:Array<Void->Void> = [];

	// fixed multi saved JSONs spamming callbacks
	static var cooldown:Float = 0;
	static final COOLDOWN_SECS:Float = 0.3;

	public static function watch(path:String, ?callback:Void->Void):Void {
		if (path == null || !FileSystem.exists(path))
			return;
		if (paths.contains(path))
			return;

		paths.push(path);
		mtimes.push(FileSystem.stat(path).mtime.getTime());
		callbacks.push(callback ?? FlxG.resetState);
	}

	public static function watchAndRead<T>(path:String, ?callback:Void->Void):Null<T> {
		watch(path, callback);
		return FormatJson.readJson(path);
	}

    public static function updateSwitch():Void {
		if (paths.length == 0)
			return;

		for (i in 0...paths.length) {
			if (!FileSystem.exists(paths[i]))
				continue;

			var currentMtime = FileSystem.stat(paths[i]).mtime.getTime();
			if (currentMtime > mtimes[i])
				mtimes[i] = currentMtime;
		}
	}

	public static function update(elapsed:Float):Void {
		if (paths.length == 0)
			return;
		if (cooldown > 0) {
			cooldown -= elapsed;
			return;
		}

		for (i in 0...paths.length) {
			if (!FileSystem.exists(paths[i]))
				continue;

			var currentMtime = FileSystem.stat(paths[i]).mtime.getTime();
			if (currentMtime > mtimes[i]) {
				mtimes[i] = currentMtime;
				cooldown = COOLDOWN_SECS;

				Console.log('JSON change detected ${paths[i]}');
				var cb = callbacks[i];
				if (cb != null)
					cb();
				break;
			}
		}
	}

	public static function clear():Void {
		paths = [];
		mtimes = [];
		callbacks = [];
		cooldown = 0;
	}

	public static function unwatch(path:String):Void {
		var i = paths.indexOf(path);
		if (i < 0)
			return;
		paths.splice(i, 1);
		mtimes.splice(i, 1);
		callbacks.splice(i, 1);
	}
}
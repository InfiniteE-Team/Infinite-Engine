package core.json;
import sys.FileSystem;

class JsonWatcher {
	static var _paths:Array<String> = [];
	static var _mtimes:Array<Float> = [];
	static var _callbacks:Array<Void->Void> = [];

	// fixed multi saved JSONs spamming callbacks
	static var _cooldown:Float = 0;
	static final COOLDOWN_SECS:Float = 0.3;

	public static function watch(path:String, ?callback:Void->Void):Void {
		if (path == null || !FileSystem.exists(path))
			return;
		if (_paths.contains(path))
			return;

		_paths.push(path);
		_mtimes.push(FileSystem.stat(path).mtime.getTime());
		_callbacks.push(callback ?? FlxG.resetState);
	}

	public static function watchAndRead<T>(path:String, ?callback:Void->Void):Null<T> {
		watch(path, callback);
		return FormatJson.readJson(path);
	}

    public static function updateSwitch():Void {
		if (_paths.length == 0)
			return;

		for (i in 0..._paths.length) {
			if (!FileSystem.exists(_paths[i]))
				continue;

			var currentMtime = FileSystem.stat(_paths[i]).mtime.getTime();
			if (currentMtime > _mtimes[i]) {
				_mtimes[i] = currentMtime;

				Trace.traceOnce('JSON change detected ${_paths[i]}');
				var cb = _callbacks[i];
				if (cb != null)
					cb();
				break;
			}
		}
	}

	public static function update(elapsed:Float):Void {
		if (_paths.length == 0)
			return;
		if (_cooldown > 0) {
			_cooldown -= elapsed;
			return;
		}

		for (i in 0..._paths.length) {
			if (!FileSystem.exists(_paths[i]))
				continue;

			var currentMtime = FileSystem.stat(_paths[i]).mtime.getTime();
			if (currentMtime > _mtimes[i]) {
				_mtimes[i] = currentMtime;
				_cooldown = COOLDOWN_SECS;

				Trace.traceOnce('JSON change detected ${_paths[i]}');
				var cb = _callbacks[i];
				if (cb != null)
					cb();
				break;
			}
		}
	}

	public static function clear():Void {
		_paths = [];
		_mtimes = [];
		_callbacks = [];
		_cooldown = 0;
	}

	public static function unwatch(path:String):Void {
		var i = _paths.indexOf(path);
		if (i < 0)
			return;
		_paths.splice(i, 1);
		_mtimes.splice(i, 1);
		_callbacks.splice(i, 1);
	}
}
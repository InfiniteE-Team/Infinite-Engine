package core.config;

import sys.FileSystem;
import utils.UtilsData;

class SaveData {
	static final path:String = 'engine/config/savedata.json';

	// configs for engine
	public var framerate:Int = 60;

	public var antialiasing:Bool = true;
	public var downscroll:Bool = false;
	public var ghosttaping:Bool = true;
	public var noteKeys:Array<String> = ['A', 'S', 'W', 'D'];

	public function new() {}

	public function saveConfig() {
		var dir = haxe.io.Path.directory(path);
		if (!FileSystem.exists(dir))
			FileSystem.createDirectory(dir);

		var data = haxe.Json.stringify(this);
		sys.io.File.saveContent(path, data);
	}

	public function loadConfig() {
		if (!FileSystem.exists(path))
			return;
		var data = UtilsData.readJson(path);
		if (data == null)
			return;

		framerate = data.framerate ?? 60;

		antialiasing = data.antialiasing ?? true;
		downscroll = data.downscroll ?? false;
		ghosttaping = data.ghosttaping ?? true;
		noteKeys = data.noteKeys ?? ['A', 'S', 'W', 'D'];
	}
}

package core.config;

import sys.FileSystem;
import utils.UtilsData;

class SaveData {
	static final path:String = 'engine/config/savedata.json';

	// configs for engine
	public var framerate:Int = 144;
	public var antialiasing:Bool = true;

	public var downscroll:Bool = false;
	public var middlescroll:Bool = false;
	public var ghosttaping:Bool = true;

	public var noteKeys:Array<String> = ['A', 'S', 'W', 'D'];
	public var uiKeys:Array<String> = ['UP', 'DOWN', 'LEFT', 'RIGHT', 'ENTER', 'ESCAPE'];

	public function new() {}

	public function saveConfig() {
		var dir = haxe.io.Path.directory(path);
		if (!FileSystem.exists(dir))
			FileSystem.createDirectory(dir);

		var data = haxe.Json.stringify(this, null, "\t");
		sys.io.File.saveContent(path, data);
	}

	public function loadConfig() {
		if (!FileSystem.exists(path))
			return;
		var data = UtilsData.readJson(path);
		if (data == null)
			return;

		for (field in Reflect.fields(data)) {
			if (Reflect.hasField(this, field)) {
				Reflect.setProperty(this, field, Reflect.field(data, field));
			}
		}
	}
}

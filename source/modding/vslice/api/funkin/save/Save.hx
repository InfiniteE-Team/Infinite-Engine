package funkin.save;

// V-Slice Save for scripts: mod options read as unset, so scripts take their defaults
// shortcut: nothing is stored, wire it to SaveData when a mod needs its options to stick -JloorDev
@:keep
class Save {
	public static var instance(get, never):Save;
	static var _instance:Save;

	static function get_instance():Save
		return _instance ??= new Save();

	public var modOptions:Map<String, Dynamic> = new Map();

	function new() {}
}

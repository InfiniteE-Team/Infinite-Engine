package core.config;

import sys.FileSystem;
import core.json.engine.SaveDataFields;

class SaveData {
	public static var data(get, never):SaveDataFields;

	static inline function get_data():SaveDataFields
		return (cast FlxG.save.data : SaveDataFields);

	static var _defaults:Map<String, Dynamic> = [];

	public function new() {}

	public static inline function flush():Void
		FlxG.save.flush();

	public static function init():Void {
		var dirty = false;
		for (key => defaultValue in _defaults) {
			if (Reflect.field(FlxG.save.data, key) == null) {
				trace('[SaveData] init: auto-creating "$key" = $defaultValue');
				Reflect.setField(FlxG.save.data, key, defaultValue);
				dirty = true;
			}
		}

		if (dirty) {
			flush();
			trace('[SaveData] init: ${_defaults.keys().hasNext() ? "fields initialized and persisted." : ""}');
		} else {
			trace('[SaveData] init: fields had already been initialized.');
		}
	}

	public static function initSave():Void {
		if (SaveData.data.framerate == null)
			SaveData.data.framerate = 60;

		if (SaveData.data.antialiasing == null)
			SaveData.data.antialiasing = true;

		if (SaveData.data.downscroll == null)
			SaveData.data.downscroll = false;

		if (SaveData.data.middlescroll == null)
			SaveData.data.middlescroll = false;

		if (SaveData.data.ghosttaping == null)
			SaveData.data.ghosttaping = true;

		if (SaveData.data.noteKeyPresets == null){
			SaveData.data.noteKeyPresets = {
				"4": [["A", "LEFT"], ["S", "DOWN"], ["W", "UP"], ["D", "RIGHT"]],
				"5": [["A"],["S"], ["SPACE"], ["W"], ["D"]],
				"6": [["A"], ["S"], ["D"], ["H"], ["J"], ["K"]],
				"7": [["A"], ["S"], ["D"], ["SPACE"], ["H"], ["J"], ["K"]],
				"8": [["A"], ["S"], ["D"], ["F"], ["H"], ["J"], ["K"], ["L"]],
				"9": [["A"], ["S"], ["D"], ["F"], ["SPACE"], ["H"], ["J"], ["K"], ["L"]]
			};
		}

		if (SaveData.data.uiKeys == null)
			SaveData.data.uiKeys = [['UP','W'], ['DOWN','S'], ['LEFT','D'], ['RIGHT','A'], ['ENTER'], ['ESCAPE']];

		flush();
	}
}

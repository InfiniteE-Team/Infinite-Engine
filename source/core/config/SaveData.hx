package core.config;

import core.json.engine.SaveDataFields;

class SaveData {
	public static var data(get, never):SaveDataFields;

	static inline function get_data():SaveDataFields
		return (cast FlxG.save.data : SaveDataFields);

	public function new() {}

	public static inline function flush():Void
		FlxG.save.flush();

	public static function initSave():Void {
		if (SaveData.data.framerate == null)
			SaveData.data.framerate = 60;

		if (SaveData.data.fpsVisible == null)
			SaveData.data.fpsVisible = true;

		if (SaveData.data.antialiasing == null)
			SaveData.data.antialiasing = true;

		if (SaveData.data.shaders == null)
			SaveData.data.shaders = true;

		if (SaveData.data.downscroll == null)
			SaveData.data.downscroll = false;

		if (SaveData.data.middlescroll == null)
			SaveData.data.middlescroll = false;

		if (SaveData.data.ghosttaping == null)
			SaveData.data.ghosttaping = true;

		if (SaveData.data.laneBackdrop == null)
			SaveData.data.laneBackdrop = 0;

		if (SaveData.data.noteKeyPresets == null){
			var presets:haxe.DynamicAccess<Array<Array<String>>> = {};
			var keys4:Array<Array<String>> = [["A", "LEFT"], ["S", "DOWN"], ["W", "UP"], ["D", "RIGHT"]];
			var keys5:Array<Array<String>> = [["A"], ["S"], ["SPACE"], ["W"], ["D"]];
			var keys6:Array<Array<String>> = [["A"], ["S"], ["D"], ["H"], ["J"], ["K"]];
			var keys7:Array<Array<String>> = [["A"], ["S"], ["D"], ["SPACE"], ["H"], ["J"], ["K"]];
			var keys8:Array<Array<String>> = [["A"], ["S"], ["D"], ["F"], ["H"], ["J"], ["K"], ["L"]];
			var keys9:Array<Array<String>> = [["A"], ["S"], ["D"], ["F"], ["SPACE"], ["H"], ["J"], ["K"], ["L"]];

			presets.set("4", keys4);
			presets.set("5", keys5);
			presets.set("6", keys6);
			presets.set("7", keys7);
			presets.set("8", keys8);
			presets.set("9", keys9);

			SaveData.data.noteKeyPresets = presets;
		}

		if (SaveData.data.uiKeys == null)
			SaveData.data.uiKeys = [['LEFT','A'], ['UP','W'], ['DOWN','S'], ['RIGHT','D'], ['ENTER'], ['ESCAPE']];

		if (SaveData.data.onMod == null)
			SaveData.data.onMod = false;

		if (SaveData.data.currentMod == null)
			SaveData.data.currentMod = '';

		if (SaveData.data.logInScreen == null)
			SaveData.data.logInScreen = true;

		flush();
	}
}

package core.config;

import flixel.input.keyboard.FlxKey;

class Controls {
	public var keyGroups:Map<String, Array<Array<FlxKey>>> = new Map();

	public function new() {
		loadGroup("noteKeys", SaveData.data.noteKeyPresets?.get("4"));
		loadGroup("uiKeys", SaveData.data.uiKeys);
	}

	private function loadGroup(groupName:String, savedKeys:Array<Array<String>>):Void {
		if (savedKeys == null)
			return;
		var keys = [for (lane in savedKeys) [for (k in lane) FlxKey.fromString(k)]];
		keyGroups.set(groupName, keys);
	}

	public function getGroupInput(groupName:String):Array<Bool> {
		if (!keyGroups.exists(groupName))
			return [];
		@:privateAccess
		return [
			for (lane in keyGroups.get(groupName))
				lane.exists(k -> FlxG.keys.pressed.check(k))
		];
	}

	public function justPressedAction(groupName:String, actionName:String):Bool {
		if (!keyGroups.exists(groupName))
			return false;
		var keys = keyGroups.get(groupName);
		var actions = ["down", "up", "left", "right", "accept", "escape"];
		var index = actions.indexOf(actionName.toLowerCase());
		if (index == -1 || index >= keys.length)
			return false;
		@:privateAccess
		return keys[index].exists(k -> FlxG.keys.justPressed.check(k));
	}

	public function justPressed(groupName:String, index:Int):Bool {
		if (!keyGroups.exists(groupName))
			return false;
		var keys = keyGroups.get(groupName);
		if (index >= keys.length)
			return false;
		@:privateAccess
		return keys[index].exists(k -> FlxG.keys.justPressed.check(k));
	}

	public function justReleased(groupName:String, index:Int):Bool {
		if (!keyGroups.exists(groupName))
			return false;
		var keys = keyGroups.get(groupName);
		if (index >= keys.length)
			return false;
		@:privateAccess
		return keys[index].exists(k -> FlxG.keys.justReleased.check(k));
	}

	public function setKey(groupName:String, laneIndex:Int, keyIndex:Int, key:FlxKey):Void {
		if (!keyGroups.exists(groupName))
			return;
		var keys = keyGroups.get(groupName);
		if (laneIndex >= keys.length)
			return;
		if (keyIndex >= keys[laneIndex].length)
			return;

		keys[laneIndex][keyIndex] = key;

		var keyStrings = [for (lane in keys) [for (k in lane) k.toString()]];
		if (groupName == "noteKeys")
			SaveData.data.noteKeyPresets.set(Std.string(keys.length), keyStrings);
		else {
			Reflect.setProperty(SaveData.data, groupName, keyStrings);
			SaveData.flush();
		}
	}

	public function loadPreset(keyCount:Int):Void {
		var presets = SaveData.data.noteKeyPresets;
		if (presets == null)
			return;
		var preset = presets.get(Std.string(keyCount));
		if (preset != null)
			loadGroup("noteKeys", preset);
	}
}

package core.config;

import flixel.input.keyboard.FlxKey;

class Controls {
	public static var instance:Controls;

	public static function init():Void {
		if (instance == null) {
			instance = new Controls();
		}
	}

	public static var UI_LEFT(get, never):Bool;

	static inline function get_UI_LEFT()
		return instance.justPressedAction("uiKeys", "left");

	public static var UI_DOWN(get, never):Bool;

	static inline function get_UI_DOWN()
		return instance.justPressedAction("uiKeys", "down");

	public static var UI_UP(get, never):Bool;

	static inline function get_UI_UP()
		return instance.justPressedAction("uiKeys", "up");

	public static var UI_RIGHT(get, never):Bool;

	static inline function get_UI_RIGHT()
		return instance.justPressedAction("uiKeys", "right");

	public static var ACCEPT(get, never):Bool;

	static inline function get_ACCEPT()
		return instance.justPressedAction("uiKeys", "accept");

	public static var BACK(get, never):Bool;

	static inline function get_BACK()
		return instance.justPressedAction("uiKeys", "escape");

	public static inline function noteJustPressed(lane:Int):Bool {
		return instance.justPressed("noteKeys", lane);
	}

	public static inline function notePressed(lane:Int):Bool {
		var inputs = instance.getGroupInput("noteKeys");
		return inputs.length > lane ? inputs[lane] : false;
	}

	public static inline function noteJustReleased(lane:Int):Bool {
		return instance.justReleased("noteKeys", lane);
	}

	public var keyGroups:Map<String, Array<Array<FlxKey>>> = new Map();

	var reverseMaps:Map<String, Map<Int, Array<Int>>> = new Map();

	public function new() {
		loadGroup("noteKeys", getPreset("4"));
		loadGroup("uiKeys", SaveData.data.uiKeys);
	}

	private function getPreset(key:String):Array<Array<String>> {
		var raw:Dynamic = SaveData.data.noteKeyPresets;
		if (raw == null)
			return null;
		var lanesRaw:Dynamic = Reflect.field(raw, key);
		if (lanesRaw == null)
			return null;
		return coerceLanes(lanesRaw);
	}

	private function coerceLanes(lanesRaw:Dynamic):Array<Array<String>> {
		var lanes:Array<Dynamic> = lanesRaw;
		var result:Array<Array<String>> = [];
		for (laneRaw in lanes) {
			var lane:Array<Dynamic> = laneRaw;
			var stringLane:Array<String> = [];
			for (k in lane)
				stringLane.push(Std.string(k));
			result.push(stringLane);
		}
		return result;
	}

	private function loadGroup(groupName:String, savedKeys:Array<Array<String>>):Void {
		if (savedKeys == null)
			return;
		var keys = [for (lane in savedKeys) [for (k in lane) FlxKey.fromString(k)]];
		keyGroups.set(groupName, keys);
		rebuildReverseMap(groupName);
	}

	function rebuildReverseMap(groupName:String):Void {
		var keys = keyGroups.get(groupName);
		if (keys == null)
			return;

		var map = new Map<Int, Array<Int>>();
		for (laneIndex in 0...keys.length) {
			for (k in keys[laneIndex]) {
				var code:Int = k;
				if (!map.exists(code))
					map.set(code, []);
				map.get(code).push(laneIndex);
			}
		}
		reverseMaps.set(groupName, map);
	}

	public function getLanesForKey(groupName:String, keyCode:Int):Array<Int> {
		var map = reverseMaps.get(groupName);
		if (map == null)
			return [];
		return map.get(keyCode) ?? [];
	}

	public function justPressedKeyCode(keyCode:Int):Bool {
		@:privateAccess
		return FlxG.keys.justPressed.check(cast keyCode);
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
		var actions = ["left", "down", "up", "right", "accept", "escape"];
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
		rebuildReverseMap(groupName);

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

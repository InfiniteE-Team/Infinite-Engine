package core.config;

import flixel.input.keyboard.FlxKey;

class Controls {
	public var save:SaveData;

	public var keyGroups:Map<String, Array<FlxKey>> = new Map();

	public function new(save:SaveData) {
		this.save = save;
		loadGroup("noteKeys", save.noteKeys);
        loadGroup("uiKeys", save.uiKeys);
	}

	private function loadGroup(groupName:String, savedKeys:Array<String>):Void {
		if (savedKeys == null)
			return;
		var keys = [for (k in savedKeys) FlxKey.fromString(k)];
		keyGroups.set(groupName, keys);
	}

	public function getGroupInput(groupName:String):Array<Bool> {
		if (!keyGroups.exists(groupName))
			return [];
		var keys = keyGroups.get(groupName);

		@:privateAccess
		return [for (key in keys) FlxG.keys.pressed.check(key)];
	}

	public function justPressed(groupName:String, index:Int):Bool {
		if (!keyGroups.exists(groupName)) return false;
        var keys = keyGroups.get(groupName);
        
        if (index >= keys.length) return false;
        
        @:privateAccess
        return FlxG.keys.justPressed.check(keys[index]);
	}

	public function justReleased(groupName:String, index:Int):Bool {
        if (!keyGroups.exists(groupName)) return false;
        var keys = keyGroups.get(groupName);
        
        if (index >= keys.length) return false;

		@:privateAccess
		return FlxG.keys.justReleased.check(keys[index]);
	}

	public function setKey(groupName:String, index:Int, key:FlxKey):Void {
		if (!keyGroups.exists(groupName)) return;
        var keys = keyGroups.get(groupName);
        
        if (index >= keys.length) return;
        
        keys[index] = key;
        
        Reflect.setProperty(save, groupName, [for (k in keys) k.toString()]);
		save.saveConfig();
	}
}

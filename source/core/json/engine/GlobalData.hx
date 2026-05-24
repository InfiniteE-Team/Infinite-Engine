package core.json.engine;

import utils.UtilsData;
import flixel.FlxState;
import game.PlayState;

typedef GlobalData = {
	var ?developerMode:Bool;
	var ?noteSkin:String;
	var ?hud:String;
	var ?startState:String;
}

class GlobalConfig {
	public var globalData:GlobalData;
	public var developerMode:Bool = true;
	public var noteSkin:String = 'default';
	public var hud:String = 'default';
	public var startState:Class<FlxState> = PlayState;

	public function new() {}

	public function configGlobal() {
		globalData = UtilsData.readJson(Paths.getPath('data/global', 'json'));
		if (globalData == null)
			return;

		noteSkin = globalData.noteSkin ?? 'default';
		hud = globalData.hud ?? 'default';
		developerMode = globalData.developerMode ?? true;
		var stateStr = globalData.startState;
		if (stateStr != null) {
			var cls:Class<FlxState> = cast(Type.resolveClass(stateStr) ?? Type.resolveClass('states.$stateStr'));
			if (cls != null)
				startState = cls;
		}
	}
}
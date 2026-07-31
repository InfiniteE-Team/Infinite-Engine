package core.json.engine;

typedef GlobalData = {
	var ?developerMode:Bool;
	var ?noteSkin:String;
	var ?hud:String;
	var ?startState:String;
	var ?skipTrans:Bool;
}

class GlobalConfig {
	public var globalData:GlobalData;
	public var developerMode:Bool = true;
	public var noteSkin:String = 'default';
	public var hud:String = 'default';
	public var startState:Class<MusicBeatState> = game.PlayState;
	public var startStateScript:String = null;
	public var skipTrans:Bool = false;

	public function new() {}

	public function configGlobal() {
		globalData = FormatJson.readJson(Paths.getPath('data/global', 'json'));
		if (globalData == null)
			return;

		noteSkin = globalData.noteSkin ?? 'default';
		hud = globalData.hud ?? 'default';
		developerMode = globalData.developerMode ?? true;
		skipTrans = globalData.skipTrans ?? false;
		
		var stateStr = globalData.startState;
		if (stateStr != null) {
			var cls:Class<MusicBeatState> = cast(Type.resolveClass(stateStr) ?? Type.resolveClass('states.$stateStr'));
			if (cls != null)
				startState = cls;
			else {
				startStateScript = stateStr;
			}
		}
	}
}

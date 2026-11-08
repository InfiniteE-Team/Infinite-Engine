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
	public var startState:String = 'TitleState';
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

		if (globalData.startState != null && globalData.startState != "") {
			startState = globalData.startState;
		}
	}

	public static var globalScripts:modding.scripting.ScriptHandler = new modding.scripting.ScriptHandler(null);

	public function loadGlobalScripts():Void {
		globalScripts.call('onDestroy', []);
		globalScripts.destroy();
		globalScripts = new modding.scripting.ScriptHandler(null);
		globalScripts.loadFolder('scripts/global');
	}
}

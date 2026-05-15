package core.json.engine;
import utils.UtilsData;
typedef GlobalData = {
	var ?developerMode:Bool;
	var ?noteSkin:String;
	var ?hud:String;
}

class GlobalConfig {
    public var globalData:GlobalData;
	public var developerMode:Bool = true;
	public var noteSkin:String = 'default';
	public var hud:String = 'default';

	public function new() {}

	public function configGlobal() {
        globalData = UtilsData.readJson(Paths.getPath('data/global', 'json'));
		if (globalData == null)
			return;

        noteSkin = globalData.noteSkin ?? 'default';
        hud = globalData.hud ?? 'default';
		developerMode = globalData.developerMode ?? true;
    }
}

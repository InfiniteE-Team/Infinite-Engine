package core.json.engine;
import utils.UtilsData;
typedef GlobalData = {
	var ?noteSkin:String;
	var ?hud:String;
}

class GlobalConfig {
    public var globalData:GlobalData;
	public var noteSkin:String;
	public var hud:String;

	public function new() {}

	public function configGlobal() {
        globalData = UtilsData.readJson(Paths.getPath('data/global', 'json'));
		if (globalData == null)
			return;

        noteSkin = globalData.noteSkin ?? 'default';
        hud = globalData.hud ?? 'default';
    }
}

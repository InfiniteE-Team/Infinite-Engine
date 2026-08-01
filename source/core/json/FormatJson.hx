package core.json;
import sys.FileSystem;
import core.json.JsonWatcher;
import ale.json.Json as AleJson;
import ale.json.Config;

class FormatJson {
	public static var _configured:Bool = false;

	public static function _configure() {
        if (_configured) return;
        _configured = true;
        Config.FILE_CHECKER = sys.FileSystem.exists;
        Config.FILE_READER = sys.io.File.getContent;
        Config.PATH = '';
        Config.EXTENSION = '';
    }

	public static function readJson<T>(data:String, ?callback:Void->Void):Null<T> {
		if (data == null || !sys.FileSystem.exists(data))
			return null;

		#if HSCRIPT_ALLOWED
		if (core.ConfigMain.globalData.developerMode)
			JsonWatcher.watch(data, callback);
		#end

		_configure();

		return cast AleJson.parse(data);
	}

	public static function getIconDataPlaceholder(?customData:core.json.objects.CharacterData.IconData):core.json.objects.CharacterData.IconData {
        if (customData == null) {
            return {
                props: null,
                bumpInBeats: true,
                stepTempo: 2.0
            };
        }

        return {
            props: customData.props != null ? customData.props : null,
            bumpInBeats: customData.bumpInBeats != null ? customData.bumpInBeats : true,
            stepTempo: customData.stepTempo != null ? customData.stepTempo : 2.0
        };
    }
}

package core.json.song;
import sys.FileSystem;
import core.json.song.ports.*;

class ChartPorter {
	static var converters:Array<FormatChartConverter> = [
		new PsychPorter(),
		new AndromedaPorter(),
        new LegacyPorter(),
        new VSlicePorter(),
        new CNEPorter()
    ];

	public static function tryConvert(raw:Dynamic):Null<SongData> {
		if (raw.meta != null)
			return null;

		for (converter in converters) {
			if (converter.detect(raw))
				return converter.convert(raw);
		}

		Trace.traceOnce('Chart Format Unknown lol', true);
		return null;
	}

	public static function tryConvertOsu(osuPath:String):Null<SongData> {
		if (osuPath == null || !FileSystem.exists(osuPath))
			return null;

		return OsuPorter.readOsu(osuPath);
	}
}

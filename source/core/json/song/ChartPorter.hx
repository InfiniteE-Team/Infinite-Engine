package core.json.song;

import core.json.song.ports.*;

class ChartPorter {
	static var converters:Array<FormatChartConverter> = [
		new PsychPorter(),
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

		trace('Chart Format Unknown lol');
		return null;
	}
}

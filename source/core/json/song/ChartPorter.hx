package core.json.song;

import sys.FileSystem;
import core.json.song.ports.*;

class ChartPorter {
	static var converters:Array<FormatChartConverter> = [new PsychPorter(), new LegacyPorter(), new VSlicePorter(), new CNEPorter()];

	public static function tryConvert(raw:Dynamic, ?diff:String, ?meta:Dynamic):Null<SongData> {
		if (raw.meta != null)
			return null;

		if (diff != null)
			Reflect.setField(raw, '_diff', diff);
		if (meta != null)
			injectVSliceMeta(raw, meta);

		for (converter in converters) {
			if (converter.detect(raw))
				return converter.convert(raw);
		}

		trace('Chart Format Unknown lol');
		return null;
	}

	public static function tryConvertOsu(osuPath:String):Null<SongData> {
		if (osuPath == null || !FileSystem.exists(osuPath))
			return null;

		return OsuPorter.readOsu(osuPath);
	}

	static function injectVSliceMeta(raw:Dynamic, meta:Dynamic):Void {
		if (meta.songName != null)
			Reflect.setField(raw, '_songName', meta.songName);

		if (meta.timeChanges != null) {
			var tc:Array<Dynamic> = cast meta.timeChanges;
			if (tc.length > 0 && tc[0].bpm != null)
				Reflect.setField(raw, '_bpm', tc[0].bpm);
		}

		if (meta.playData != null) {
			var pd:Dynamic = meta.playData;
			if (pd.stage != null)
				Reflect.setField(raw, '_stage', pd.stage);

			if (pd.characters != null) {
				var ch:Dynamic = pd.characters;
				if (ch.player != null)
					Reflect.setField(raw, '_player', ch.player);
				if (ch.opponent != null)
					Reflect.setField(raw, '_opponent', ch.opponent);
				if (ch.girlfriend != null)
					Reflect.setField(raw, '_girlfriend', ch.girlfriend);

				if (ch.instrumental != null && ch.instrumental != '')
					Reflect.setField(raw, '_instCustom', Std.string(ch.instrumental));

				var playerVocs:Array<Dynamic> = ch.playerVocals != null ? cast ch.playerVocals : [];
				var opponentVocs:Array<Dynamic> = ch.opponentVocals != null ? cast ch.opponentVocals : [];
				if (playerVocs.length > 0 || opponentVocs.length > 0) {
					var stems:Array<String> = [];
					for (id in playerVocs)
						stems.push('Voices-' + Std.string(id));
					for (id in opponentVocs)
						stems.push('Voices-' + Std.string(id));
					Reflect.setField(raw, '_vocs', stems);
				}
			}
		}
	}
}

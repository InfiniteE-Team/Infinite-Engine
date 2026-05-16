package core.json.song.ports;

import utils.UtilsData;

interface FormatChartConverter {
    public function detect(raw:Dynamic):Bool;
    public function convert(raw:Dynamic):SongData;
}
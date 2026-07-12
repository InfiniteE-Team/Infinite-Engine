package core.json.song.ports;

interface FormatChartConverter {
    public function detect(raw:Dynamic):Bool;
    public function convert(raw:Dynamic):SongData;
}
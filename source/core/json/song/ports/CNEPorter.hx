package core.json.song.ports;

class CNEPorter implements FormatChartConverter {
    public function new () {}
    public function detect(raw:Dynamic):Bool {
        return raw.Format != null && raw.Format == 'CNE';
    }

    public function convert(raw:Dynamic):SongData {
        return null;
    }
}
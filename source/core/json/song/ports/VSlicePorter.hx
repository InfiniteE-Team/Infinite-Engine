package core.json.song.ports;

class VSlicePorter implements FormatChartConverter {
    public function new () {}
    public function detect(raw:Dynamic):Bool {
        return raw.version != null && raw.notes != null && raw.scrollSpeed != null;
    }

    public function convert(raw:Dynamic):SongData {
        return null;
    }
}
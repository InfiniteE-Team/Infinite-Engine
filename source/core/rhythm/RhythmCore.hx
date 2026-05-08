package core.rhythm;

class RhythmCore
{
    public static var bpm:Float = 100.0;
    public static var crochet:Float = 600.0;
    public static var stepInMs:Float = 150;

    public static var songPosition:Float = 0;

    public static function changeBPM(newBPM:Float):Void
    {
        bpm = newBPM;
        crochet = 60000.0 / bpm;
        stepInMs = crochet * 0.25;
    }
}
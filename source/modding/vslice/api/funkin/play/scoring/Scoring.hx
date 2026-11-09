package funkin.play.scoring;

// uses the engine's rating windows whatever system is asked for -JloorDev
@:keep
class Scoring {
	public static var PBOT1_SICK_THRESHOLD:Float = 45;
	public static var PBOT1_GOOD_THRESHOLD:Float = 90;
	public static var PBOT1_BAD_THRESHOLD:Float = 135;
	public static var PBOT1_SHIT_THRESHOLD:Float = 160;
	public static var PBOT1_MISS_THRESHOLD:Float = 160;

	static function rating(diff:Float):Dynamic
		return game.PlayState.instance?.noteController?.getRatingForDiff(Math.abs(diff));

	public static function scoreNote(msTiming:Float, ?scoringSystem:String):Int
		return rating(msTiming)?.score ?? 0;

	public static function judgeNote(msTiming:Float, ?scoringSystem:String):String
		return rating(msTiming)?.rating ?? 'miss';

	public static function getMissScore(?scoringSystem:String):Int
		return game.PlayState.instance?.noteController?.getMissScore() ?? -10;
}

package funkin.util;

// the V-Slice constants scripts read (camera bops, steps per beat) -JloorDev
@:keep
class Constants {
	public static var STEPS_PER_BEAT:Int = 4;
	public static var BEATS_PER_MEASURE:Int = 4;
	public static var DEFAULT_BOP_INTENSITY:Float = 1.015;
	public static var DEFAULT_ZOOM_RATE:Int = 4;
	public static var DEFAULT_ZOOM:Float = 1.05;
	public static var PIXELS_PER_MS:Float = 0.45;
	public static var HEALTH_MAX:Float = 2.0;
	public static var HEALTH_MIN:Float = 0.0;
	public static var HEALTH_STARTING:Float = 1.0;
	public static var HEALTH_SICK_BONUS:Float = 0.03;
	public static var HEALTH_GOOD_BONUS:Float = 0.015;
	public static var HEALTH_BAD_BONUS:Float = 0.0;
	public static var HEALTH_SHIT_BONUS:Float = -0.02;
	public static var HEALTH_MISS_PENALTY:Float = -0.08;
	public static var HEALTH_GHOST_MISS_PENALTY:Float = -0.04;
	public static var SCORE_GHOST_MISS_PENALTY:Int = -10;
	public static var JUDGEMENT_SICK_COMBO_BREAK:Bool = false;
	public static var JUDGEMENT_GOOD_COMBO_BREAK:Bool = false;
	public static var JUDGEMENT_BAD_COMBO_BREAK:Bool = true;
	public static var JUDGEMENT_SHIT_COMBO_BREAK:Bool = true;
	public static var VERSION:String = 'Infinite Engine';
}

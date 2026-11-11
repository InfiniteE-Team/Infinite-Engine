package game;

class PlayStateConfig {
	// note
	public static inline var strumLineY:Float = 40.0;

	// gameplay
	public var health(default, set):Float = 1.0;

	function set_health(value:Float):Float {
		return health = flixel.math.FlxMath.bound(value, 0, 2);
	}

	public var score:Int = 0;

	public var misses:Int = 0;

	public var combo:Int = 0;

	public var rating:String = "N/A";

	public var hitNotes:Int = 0;

	public var totalNotes:Int = 0;

	public static var isPlaying:Bool = false;

	public var isBotplay:Bool = false;

	// set by scripts for a moment (a minigame), never saved -JloorDev
	public var autoPlay:Bool = false;
	public var inputLocked:Bool = false;

	public var botplayOn(get, never):Bool;

	function get_botplayOn():Bool
		return SaveData.data.botplay || autoPlay;

	public static var blueBalled:Int = 0;

	// storymode
	public static var isStoryMode:Bool = false;
	public static var curWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyWeekName:String = "";
	public static var storyScore:Int = 0;

	public static var ratingSkin:String = 'default';

	//

	public function new() {}

	public function reset() {
		health = 1.0;
		score = 0;
		misses = 0;
		rating = "N/A";
		combo = 0;
		hitNotes = 0;
		totalNotes = 0;
		ratingType = 'default';
	}
}

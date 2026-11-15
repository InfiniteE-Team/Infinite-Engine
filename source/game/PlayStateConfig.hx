package game;

class PlayStateConfig {
	public static inline var strumLineY:Float = 40.0;

	// gameplay
	public var health(default, set):Float = 1.0;

	function set_health(value:Float):Float {
		return health = flixel.math.FlxMath.bound(value, 0, 2);
	}

	public var rating:String = "sick";
	public var isBotplay:Bool = false;
	// set by scripts for a moment (a minigame), never saved -JloorDev
	public var autoPlay:Bool = false;
	public var inputLocked:Bool = false;

	public var botplayOn(get, never):Bool;

	function get_botplayOn():Bool
		return SaveData.data.botplay || autoPlay;

	// stats
	public static var score:Int = 0;
	public static var misses:Int = 0;
	public static var combo:Int = 0;
	public static var hitNotes:Int = 0;
	public static var totalNotes:Int = 0;
	public static var blueBalled:Int = 0;

	public static var isPlaying:Bool = false;

	// storymode
	public static var isStoryMode:Bool = false;
	public static var curWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyWeekName:String = "";
	public static var storyScore:Int = 0;

	public static var comboSkin:String = 'default';

	//

	public function new() {}

	public function reset() {
		health = 1.0;
		score = 0;
		misses = 0;
		rating = "sick";
		combo = 0;
		hitNotes = 0;
		totalNotes = 0;
		comboSkin = 'default';
	}
}

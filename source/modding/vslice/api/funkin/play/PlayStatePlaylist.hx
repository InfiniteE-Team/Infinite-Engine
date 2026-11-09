package funkin.play;

// V-Slice PlayStatePlaylist for scripts, read from the engine's story flag -JloorDev
@:keep
class PlayStatePlaylist {
	public static var isStoryMode(get, never):Bool;
	public static var campaignId:String = null;
	public static var campaignTitle:String = null;
	public static var campaignScore:Int = 0;
	public static var campaignDifficulty:String = 'normal';
	// the engine's own list, so a script swapping the next song (lesson -> lesson-good) really changes it -JloorDev
	public static var playlistSongIds(get, never):Array<String>;

	static function get_isStoryMode():Bool
		return game.PlayStateConfig.isStoryMode;

	static function get_playlistSongIds():Array<String>
		return game.PlayStateConfig.storyPlaylist;

	public static function reset():Void {
		campaignId = campaignTitle = null;
		campaignScore = 0;
		campaignDifficulty = 'normal';
	}
}

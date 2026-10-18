package funkin.play;

// V-Slice PlayStatePlaylist for scripts, read from the engine's story flag -JloorDev
@:keep
class PlayStatePlaylist {
	public static var isStoryMode(get, never):Bool;
	public static var campaignId:String = null;
	public static var campaignScore:Int = 0;
	public static var playlistSongIds:Array<String> = [];

	static function get_isStoryMode():Bool
		return game.PlayStateConfig.isStoryMode;
}

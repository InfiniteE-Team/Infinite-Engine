package core.json.engine.storymenu;

typedef WeekData = {
	var week:String;
	var priority:Int;
	var weekGraphic:String;
	var chars:Array<String>;
	var description:String;
	var songs:Array<FreeplayData.SongData>;
	var ?stickerPack:String;
}

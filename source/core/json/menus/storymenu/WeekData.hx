package core.json.menus.storymenu;

typedef WeekData = {
	var week:String;
	var priority:Int;
	var weekGraphic:String;
	var chars:Array<String>;
	var description:String;
	var songs:Array<FreeplayData.SongData>;
	var ?stickerPack:String;
	var ?color:String;
	var ?charProps:Array<core.json.extensions.SpriteData.ObjectData>;
}

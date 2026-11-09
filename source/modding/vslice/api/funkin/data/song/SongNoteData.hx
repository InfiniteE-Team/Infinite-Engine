package funkin.data.song;

@:keep
class SongNoteData {
	public var time:Float;
	public var data:Int;
	public var length:Float;
	public var kind:String;

	public function new(time:Float, data:Int, length:Float = 0, kind:String = '') {
		this.time = time;
		this.data = data;
		this.length = length;
		this.kind = kind;
	}

	public function getDirection(strumlineSize:Int = 4):Int
		return data % strumlineSize;

	public function getMustHitNote(strumlineSize:Int = 4):Bool
		return data < strumlineSize;
}

package funkin.play.event;

// a mod's own song event, the chart editor lists it with its schema -JloorDev
@:scriptable
@:keepSub
@:keep
class SongEvent {
	public var id:String;

	public function new(id:String, ?params:Dynamic) {
		this.id = id;
	}

	public function handleEvent(data:Dynamic):Void {}

	public function getTitle():String
		return id;

	public function getEventSchema():Dynamic
		return [];

	public function precacheEvent(data:Dynamic):Void {}

	public function toString():String
		return 'SongEvent($id)';
}

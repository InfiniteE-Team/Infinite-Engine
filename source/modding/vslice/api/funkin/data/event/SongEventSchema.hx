package funkin.data.event;

@:keep
class SongEventSchema {
	public var fields:Array<Dynamic>;

	public function new(?fields:Array<Dynamic>)
		this.fields = fields ?? [];
}

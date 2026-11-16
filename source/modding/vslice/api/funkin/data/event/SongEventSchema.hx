package funkin.data.event;


class SongEventSchema {
	public var fields:Array<Dynamic>;

	public function new(?fields:Array<Dynamic>)
		this.fields = fields ?? [];
}

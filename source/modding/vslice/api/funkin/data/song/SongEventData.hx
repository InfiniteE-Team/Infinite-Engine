package funkin.data.song;

@:keep
class SongEventData {
	public var time:Float;
	public var eventKind:String;
	public var value:Dynamic;
	public var activated:Bool = false;

	public function new(time:Float, eventKind:String, ?value:Dynamic) {
		this.time = time;
		this.eventKind = eventKind;
		this.value = value;
	}

	public function getDynamic(key:String):Dynamic
		return value == null || key == null ? value : Reflect.field(value, key);

	public function getBool(key:String):Null<Bool> {
		var v:Dynamic = getDynamic(key);
		return v == null ? null : (v == true || v == 'true');
	}

	public function getFloat(key:String):Null<Float> {
		var v:Dynamic = getDynamic(key);
		return v == null ? null : (Std.isOfType(v, String) ? Std.parseFloat(v) : v);
	}

	public function getInt(key:String):Null<Int> {
		var f = getFloat(key);
		return f == null ? null : Std.int(f);
	}

	public function getString(key:String):String {
		var v:Dynamic = getDynamic(key);
		return v == null ? null : Std.string(v);
	}

	public function getArray(key:String):Array<Dynamic>
		return getDynamic(key);
}

package core.json.song;

typedef SongData = {
	var meta:MetaData;
	var gameplay:GameplayData;
	var notes:Array<NoteData>;
}

typedef MetaData = {
	var song:String;
	var bpm:Float;
	var speed:Float;
	var ?stage:String;
	var ?countdown:String;
	var ?needVoices:Bool;
	var ?instPrefix:Null<String>;
	var ?vocPrefix:Null<String>;
	var ?vocs:Null<Array<String>>;
}

typedef GameplayData = {
	var chars:Array<CharDataJson>;
	var events:Array<EventsData>;
}

typedef CharDataJson = {
	// general
	var id:String;
	var ?name:String;
	var ?role:String;

	// song
	var ?vocals:String;

	// stages
	var ?position:Array<Float>;
	var ?camPos:Array<Float>;

	// strums song
	var strums:StrumsData;
}

typedef StrumsData = {
	var ?noteSkin:String;
	var ?position:Array<Float>;
	var ?scale:Array<Float>;
	var ?visible:Bool;
	var ?notesVisible:Bool;
}

typedef EventsData = {
	var arguments:Dynamic;
	var time:Float;
	var name:String;
}

typedef NoteData = {
	var ?char:Null<String>;
	var ?lane:Null<Int>;
	var ?time:Null<Float>;
	var ?type:Null<String>;
	var ?length:Null<Float>;

	// v2
	var ?l:Null<Int>;
	var ?t:Null<Float>;
	var ?d:Null<Int>;
	var ?c:Null<String>;
}

class NoteDataUtil {
	public static function normalize(notes:Array<NoteData>, lbase:Float):Void {
		for (n in notes) {
			if (n.l == null && n.t == null && n.d == null && n.c == null)
				continue;

			if (n.lane == null)
				n.lane = n.l ?? 0;
			if (n.time == null)
				n.time = n.t ?? 0.0;
			if (n.char == null)
				n.char = n.c ?? '';
			if (n.type == null)
				n.type = 'normal';
			if (n.length == null)
				n.length = (n.d != null && lbase > 0) ? n.d * lbase : 0.0;

			Reflect.deleteField(n, 'l');
			Reflect.deleteField(n, 't');
			Reflect.deleteField(n, 'd');
			Reflect.deleteField(n, 'c');
		}
	}

	public static function toV2(notes:Array<NoteData>, lbase:Float):Array<Dynamic> {
		var out:Array<Dynamic> = [];
		for (n in notes) {
			var d:Dynamic = {
				l: n.lane,
				t: n.time,
				c: n.char
			};
			var lenIdx:Int = (lbase > 0) ? Math.round((n.length ?? 0) / lbase) : 0;
			Reflect.setField(d, 'd', lenIdx);
			if (n.type != null && n.type != 'normal')
				Reflect.setField(d, 'type', n.type);
			out.push(d);
		}
		return out;
	}
}

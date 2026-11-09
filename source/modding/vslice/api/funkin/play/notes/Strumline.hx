package funkin.play.notes;

import game.objects.sprites.notes.StrumNote;

// V-Slice Strumline for scripts: one side's arrows, enough for cutscenes fading or hiding them
// shortcut: only alpha/visible/x/y offsets; notes, hold covers and per-strumline speed aren't separate here -JloorDev

@:keep
class Strumline {
	public var isPlayer(default, null):Bool;

	public var notes(default, null):StrumlineNotes;

	public function new(isPlayer:Bool) {
		this.isPlayer = isPlayer;
		notes = new StrumlineNotes(isPlayer);
	}

	public var alpha(get, set):Float;
	public var visible(get, set):Bool;

	function arrows():Array<StrumNote> {
		var ps = game.PlayState.instance;
		if (ps?.chars == null || ps.noteController == null)
			return [];
		var result:Array<StrumNote> = [];
		var side:Array<game.objects.sprites.Character> = isPlayer ? @:privateAccess ps.chars.playerChars : @:privateAccess ps.chars.opponentChars;
		for (c in side)
			result = result.concat(ps.noteController.getCharStrums(c.id));
		return result;
	}

	public static var INITIAL_OFFSET:Float = 0;
	public static var STRUMLINE_SIZE:Float = 104;

	public var strumlineNotes(get, never):{members:Array<StrumNote>};

	function get_strumlineNotes() {
		groupX();
		return {members: arrows()};
	}

	// V-Slice's x is the group's, it stays put when single arrows move -JloorDev
	var _groupX:Null<Float> = null;

	function groupX():Float {
		if (_groupX == null) {
			var a = arrows();
			if (a.length == 0)
				return 0;
			// arrows sit 0.275 of an arrow inside the group; +4 matched V-Slice on screen -JloorDev
			_groupX = a[0].x - 0.275 * STRUMLINE_SIZE + 4;
		}
		return _groupX;
	}

	public var width(get, never):Float;

	function get_width():Float {
		var a = arrows();
		return a.length > 0 ? a[a.length - 1].x + a[a.length - 1].width - a[0].x : 0;
	}

	public var scrollSpeed(get, never):Float;

	function get_scrollSpeed():Float {
		var ps = game.PlayState.instance;
		var side:Array<game.objects.sprites.Character> = [];
		if (ps?.chars != null)
			side = isPlayer ? @:privateAccess ps.chars.playerChars : @:privateAccess ps.chars.opponentChars;
		var line = side.length > 0 ? ps.noteController?.getStrumline(side[0].id) : null;
		return line?.scrollSpeed ?? ps?.noteController?.scrollSpeed ?? 1.0;
	}

	public var isDownscroll(get, never):Bool;

	function get_isDownscroll():Bool
		return SaveData.data.downscroll == true;

	public var showNotesplash:Bool = false;
	public var noteStyle:funkin.play.notes.notestyle.NoteStyle = new funkin.play.notes.notestyle.NoteStyle('funkin');
	public var onNoteIncoming:flixel.util.FlxSignal.FlxTypedSignal<Dynamic->Void> = new flixel.util.FlxSignal.FlxTypedSignal<Dynamic->Void>();
	public var holdNotes:Array<Dynamic> = [];
	public var noteSplashes:{members:Array<Dynamic>} = {members: []};

	// the engine already handled the hit -JloorDev
	public function hitNote(note:Dynamic, ?removeNote:Bool):Void {}

	public function playNoteSplash(direction:Int):Void {}

	public function getXPos(direction:Int):Float {
		var s = getByIndex(direction);
		return s != null ? s.x - x : 0;
	}

	public function getByIndex(index:Int):StrumNote {
		var a = arrows();
		if (index < 0 || index >= a.length)
			return null;
		return a[index];
	}

	public function getByDirection(direction:Int):StrumNote {
		return getByIndex(direction);
	}

	public function playStatic(direction:Int):Void {
		var s = getByIndex(direction);
		if (s != null)
			s.playAnim('static', true);
	}

	public function playPress(direction:Int):Void {
		var s = getByIndex(direction);
		if (s != null)
			s.playAnim('pressed', false);
	}

	public function playConfirm(direction:Int):Void {
		var s = getByIndex(direction);
		if (s != null)
			s.playAnim('confirm', true);
	}

	public var x(get, set):Float;

	function get_x():Float
		return groupX();

	function set_x(v:Float):Float {
		var a = arrows();
		if (a.length == 0)
			return v;
		var offset = v - groupX();
		for (s in a)
			s.x += offset;
		_groupX = v;
		return v;
	}

	public var y(get, set):Float;

	function get_y():Float {
		var a = arrows();
		return a.length > 0 ? a[0].y : 0;
	}

	function set_y(v:Float):Float {
		var a = arrows();
		if (a.length == 0)
			return v;
		var offset = v - a[0].y;
		for (s in a)
			s.y += offset;
		return v;
	}

	function get_alpha():Float {
		var a = arrows();
		return a.length > 0 ? a[0].alpha : 1;
	}

	function set_alpha(v:Float):Float {
		for (s in arrows())
			s.alpha = v;
		return v;
	}

	function get_visible():Bool {
		var a = arrows();
		return a.length > 0 ? a[0].visible : true;
	}

	function set_visible(v:Bool):Bool {
		for (s in arrows())
			s.visible = v;
		return v;
	}
}

// shortcut: alpha/visible reach the notes on screen now, notes spawned later keep their own until set again -JloorDev

@:keep
class StrumlineNotes {
	var isPlayer:Bool;
	var _alpha:Float = 1;
	var _visible:Bool = true;

	public function new(isPlayer:Bool) {
		this.isPlayer = isPlayer;
	}

	public var alpha(get, set):Float;
	public var visible(get, set):Bool;

	function each(f:flixel.FlxSprite->Void):Void {
		var nc = game.PlayState.instance?.noteController;
		if (nc == null)
			return;
		var groups:Array<Array<Dynamic>> = [cast nc.notes.members, cast nc.sustains.members];
		for (group in groups)
			for (n in group)
				if (n != null && n.alive && Reflect.field(n, 'mustPress') == isPlayer)
					f(n);
	}

	function get_alpha():Float
		return _alpha;

	function set_alpha(v:Float):Float {
		_alpha = v;
		each(n -> n.alpha = v);
		return v;
	}

	function get_visible():Bool
		return _visible;

	function set_visible(v:Bool):Bool {
		_visible = v;
		each(n -> n.visible = v);
		return v;
	}
}

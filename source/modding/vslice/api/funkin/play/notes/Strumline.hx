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

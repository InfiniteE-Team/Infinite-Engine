package funkin.play;

import core.config.Controls;

// PlayState.instance.controls for V-Slice scripts, read from the engine's UI keys (accept skips cutscenes) -JloorDev
@:keep
class ScriptControls {
	public function new() {}

	public var ACCEPT(get, never):Bool;
	public var ACCEPT_P(get, never):Bool;
	public var BACK(get, never):Bool;
	public var BACK_P(get, never):Bool;
	public var CUTSCENE_ADVANCE(get, never):Bool;
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var PAUSE(get, never):Bool;

	function get_ACCEPT():Bool
		return Controls.ACCEPT;

	function get_ACCEPT_P():Bool
		return Controls.ACCEPT;

	function get_BACK():Bool
		return Controls.BACK;

	function get_BACK_P():Bool
		return Controls.BACK;

	function get_CUTSCENE_ADVANCE():Bool
		return Controls.ACCEPT;

	function get_UI_UP_P():Bool
		return Controls.UI_UP;

	function get_UI_DOWN_P():Bool
		return Controls.UI_DOWN;

	function get_UI_LEFT_P():Bool
		return Controls.UI_LEFT;

	function get_UI_RIGHT_P():Bool
		return Controls.UI_RIGHT;

	function get_PAUSE():Bool
		return false;

	public function getDialogueNameFromToken(token:String, ?gamepad:Bool):String
		return token;
}

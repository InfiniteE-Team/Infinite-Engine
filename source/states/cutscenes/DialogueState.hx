package states.cutscenes;

import core.json.song.DialogueData;

class DialogueState extends flixel.group.FlxSpriteGroup {
	// dialogues for time
	var timeline:Float = 0;
	// dialogues for shifts
	var shifts:Int = 0;
	var shiftSubject:String = 'dad';
	var dialog:String = 'dame mortadela bro';

	public var elements:Array<FunkinSprite> = [];

	var dialogueData:DialogueData;

	public function new() {
		super();
		createDialogues();
	}

	public function createDialogues() {}
}

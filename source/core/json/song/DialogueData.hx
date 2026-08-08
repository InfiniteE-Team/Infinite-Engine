package core.json.song;
import core.enums.ElementType;
import core.json.extensions.AudioData;
import core.json.objects.StageData.StageElement;
import core.json.extensions.SpriteData.ObjectData;

typedef DialogueData = {
	var elements:Array<StageElement>;
	var dialogues:Array<Shifts>;
}

typedef Shifts = {
	var shift:String;
	var time:Float;
	var dialog:String;
}

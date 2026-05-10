package game.objects.sprites;
import flixel.FlxBasic;
import core.json.objects.StageData;
import flixel.group.FlxGroup.FlxTypedGroup;

class Stage extends FlxTypedGroup<FlxBasic> {
	public function new() {
		super();
		createStage();
	}

	public function createStage() {}
}

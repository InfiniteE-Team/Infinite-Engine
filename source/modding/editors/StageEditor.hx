package modding.editors;

class StageEditor extends MusicBeatState {
	var stage:game.objects.sprites.Stage;

	var pieces:Array<core.assets.FunkinSprite> = [];

	public function new() {
        super();
    }

	override public function create() {
		super.create();

		if (FlxG.mouse != null)
			FlxG.mouse.visible = true;
	}
}

package game.objects.sprites;

import flixel.FlxBasic;
import utils.UtilsData;
import core.assets.FunkinSprite;
import core.json.objects.StageData;
import flixel.group.FlxGroup.FlxTypedGroup;

class Stage extends FlxTypedGroup<FlxBasic> {
	var stage:String = 'stage';

	public var defaultZoom(get, never):Float;
	function get_defaultZoom()
		return stageData?.defaultZoom ?? 1.0;

	public var stageData:StageData;
	public var elements:Array<FunkinSprite> = [];
	public var charProps:Map<String, StageElement> = [];
	public var hideGF:Bool = false;

	public var charLayer:FlxTypedGroup<FlxBasic> = new FlxTypedGroup();

	public function new(stage:String) {
		super();
		this.stage = stage;
		dataStage();
		createStage();
	}

	public function dataStage() {
		var stageDataPath = Paths.getPath('data/stages/' + stage, "json");
		stageData = UtilsData.readJson(stageDataPath);
	}

	public function createStage() {
		if (stageData == null)
			return;
		hideGF = stageData.hideGF ?? false;
		var charLayerAdded = false;

		for (element in stageData.elements){
			var type:String = Std.string(element.type ?? 'sprite');

			if (type == 'character') {
				if (!charLayerAdded) {
					add(charLayer);
					charLayerAdded = true;
				}
				if (element.id != null)
					charProps.set(element.id, element);
			} else {
				createElement(element);
			}
		}

		if (!charLayerAdded)
        	add(charLayer);
	}

	public function applyCharProps(char:FunkinSprite, id:String) {
		var props = charProps.get(id);
		if (props == null) {
			Trace.traceOnce('Not exist chars $id');
			return;
		}
		if (props.position != null)
        	char.setPosition(char.x + props.position[0], char.y + props.position[1]);
	}

	function createElement(element:StageElement) {
		var type:String = Std.string(element.type ?? 'sprite');
		switch (type) {
			case 'animated' | 'sprite' | 'group':
				var sprite = new FunkinSprite(0, 0);
				sprite.loadProps(element.props, 'stages/$stage');
				if (element.velocityX != null)
					sprite.velocity.x = element.velocityX;
				if (element.velocityY != null)
					sprite.velocity.y = element.velocityY;
				elements.push(sprite);
				add(sprite);

			case 'graphic':
				var sprite = new FunkinSprite(0, 0);
				sprite.loadMakeGraphic(element.props);
				elements.push(sprite);
				add(sprite);

			case 'sound':
				if (element.audio?.path != null)
					FlxG.sound.play(Paths.getPath('stages/' + element.audio.path, 'sound'), element.audio.volume ?? 1.0, element.audio.looped ?? false);

			default:
				Trace.traceOnce('Element Type Unknown $type');
		}
	}

	override public function destroy() {
		for (element in elements)
        	element.destroy();
		elements = null;
		charProps = null;
		charLayer.destroy();
		charLayer = null;
		super.destroy();
	}
}
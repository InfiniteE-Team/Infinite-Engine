package game.objects.sprites;

import flixel.FlxBasic;
import core.assets.FunkinSprite;
import core.json.objects.StageData;
import flixel.group.FlxGroup.FlxTypedGroup;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

class Stage extends FlxTypedGroup<FlxBasic> {
	var stage:String = 'stage';

	public var defaultZoom(get, never):Float;

	function get_defaultZoom()
		return stageData?.defaultZoom ?? 1.0;

	public var stageData:StageData;
	public var elements:Array<FunkinSprite> = [];
	public var charProps:Map<String, StageElement> = [];
	public var hideGF:Bool = false;

	public var objectMap:Map<String, FunkinSprite> = new Map();

	public var charLayer:FlxTypedGroup<FlxBasic> = new FlxTypedGroup();

	#if HSCRIPT_ALLOWED
	public var stageScript:ScriptHandler;
	#end

	public function new(stage:String) {
		super();
		this.stage = stage;
		#if HSCRIPT_ALLOWED
		initStageScript();
		#end
		createStage();
	}

	#if HSCRIPT_ALLOWED
	function initStageScript():Void {
		stageScript = new ScriptHandler(this);
		stageScript.load(Paths.getPath('stages/$stage', 'script'));
		stageScript.executeAll();
		stageScript.call('onCreate', []);
	}
	#end

	public function createStage() {
		// hardcoder reference!1
		switch (stage) {
			default:
				var stageDataPath = Paths.getPath('data/stages/' + stage, "json");
				stageData = modding.vslice.VSliceStages.readStage(stageDataPath);

				if (stageData == null)
					return;

				if (stageData.elements == null) {
					Console.log('[Stage] WARNING: "$stage" is not a stage format the engine reads, using stage', true);
					stage = 'stage';
					stageData = FormatJson.readJson('${core.assets.Library.baseFolder}/data/stages/stage.json');
					if (stageData == null || stageData.elements == null) {
						stageData = null;
						return;
					}
				}

				hideGF = stageData.hideGF ?? false;
				var charLayerAdded = false;

				for (element in stageData.elements) {
					var type:String = Std.string(element.type ?? 'sprite');

					if (type == 'character') {
						if (!charLayerAdded) {
							add(charLayer);
							charLayerAdded = true;
							charLayerZ = element.zIndex ?? 0;
						}
						if (element.id != null)
							charProps.set(element.id, element);
					} else {
						createElement(element);
					}
				}

				if (Lambda.exists(stageData.elements, e -> e.zIndex != null))
					runVSliceScript();
		}
	}

	var vsliceScript:funkin.play.stage.Stage = null;
	var brokenHooks:Map<String, Bool> = new Map();
	var charLayerZ:Int = 0;

	function runVSliceScript():Void {
		try {
			vsliceScript = modding.vslice.VSliceScripts.loadStageScript(this, stage);
		} catch (e:Dynamic) {
			Console.log('[V-Slice] could not load the script of "$stage": $e', true);
		}
		if (vsliceScript == null)
			return;

		callVSlice('buildStage', null);
		callVSlice('onCreate', {});
		sortByZ();
		modding.vslice.VSliceHooks.register(vsliceScript);
	}

	function callVSlice(hook:String, e:Dynamic):Void {
		if (vsliceScript == null || brokenHooks.exists(hook))
			return;
		try {
			if (hook == 'buildStage')
				vsliceScript.buildStage();
			else
				Reflect.callMethod(vsliceScript, Reflect.field(vsliceScript, hook), [e]);
		} catch (err:Dynamic) {
			brokenHooks.set(hook, true);
			Console.log('[V-Slice] $stage.$hook failed, skipping it from now on: $err', true);
		}
	}

	public function addScripted(obj:FlxBasic):Void
		add(obj);

	var extraChars:Map<FlxBasic, Character> = new Map();

	public function addExtraCharacter(char:Character):Void {
		var group = new FlxTypedGroup<FlxBasic>();
		for (layer in char.layers)
			group.add(layer);
		group.add(char);
		extraChars.set(group, char);
		add(group);
		sortByZ();
	}

	public function sortByZ():Void {
		var order = [for (i in 0...members.length) members[i] => i];
		var list = [for (m in members) if (m != null) m];
		haxe.ds.ArraySort.sort(list, (a, b) -> {
			var d = zOf(a) - zOf(b);
			return d != 0 ? d : order.get(a) - order.get(b);
		});
		for (i in 0...list.length)
			members[i] = list[i];
	}

	function zOf(obj:FlxBasic):Int {
		if (obj == charLayer)
			return charLayerZ;
		if (extraChars.exists(obj))
			return extraChars.get(obj).zIndex;
		var z:Dynamic = Reflect.getProperty(obj, 'zIndex');
		return z != null ? Std.int(z) : 0;
	}

	public function getCharacterByRole(role:String):Null<Character> {
		for (m in charLayer.members) {
			var c = Std.downcast(m, Character);
			if (c != null && c.id == role)
				return c;
		}
		return null;
	}

	public function applyCharProps(char:FunkinSprite, id:String) {
		var props = charProps.get(id);
		if (props == null) {
			Console.log('Not exist chars $id', true);
			return;
		}

		if (props.position != null) {
			var x = props.position[0];
			var y = props.position[1];
			var body = Std.isOfType(char, Character) ? cast(char, Character).layers[0] : null;
			if (props.anchorFeet == true && body != null) {
				x -= body.width * 0.5;
				y -= body.height;
			}
			char.setPosition(char.x + x, char.y + y);
		}

		if (props.alpha != null && Std.isOfType(char, Character))
			for (layer in cast(char, Character).layers)
				layer.alpha = props.alpha;
	}



	function createElement(element:StageElement) {
		var type:String = Std.string(element.type ?? 'sprite');
		switch (type) {
			case 'animated' | 'sprite' | 'group':
				var sprite:FunkinSprite;
				if (element.zIndex != null) {
					var prop = new funkin.play.stage.StageProp(0, 0);
					prop.zIndex = element.zIndex;
					prop.danceEvery = element.props?.danceEvery ?? 0;
					prop.bopAnims = element.props?.bopAnims;
					sprite = prop;
				} else
					sprite = new FunkinSprite(0, 0);
				sprite.loadProps(element.props, 'game/stages/$stage');
				elements.push(sprite);
				add(sprite);

				if (element.props?.name != null)
					objectMap.set(element.props.name, sprite);

			case 'backdrop':
				var sprite = new core.assets.FunkinBackdrop(0, 0);
				sprite.loadProps(element.props, 'game/stages/$stage');
				if (element.props.velocityX != null)
					sprite.velocityX = element.props.velocityX;
				if (element.props.velocityY != null)
					sprite.velocityY = element.props.velocityY;
				if (element.props.repeatX != null)
					sprite.repeatX = element.props.repeatX;
				if (element.props.repeatY != null)
					sprite.repeatY = element.props.repeatY;
				elements.push(sprite);
				add(sprite);

				if (element.props?.name != null)
					objectMap.set(element.props.name, sprite);
			case 'graphic':
				var sprite:FunkinSprite = new FunkinSprite(0, 0);
				if (element.zIndex != null) {
					var prop = new funkin.play.stage.StageProp(0, 0);
					prop.zIndex = element.zIndex;
					sprite = prop;
				}
				sprite.loadMakeGraphic(element.props);
				elements.push(sprite);
				add(sprite);

				if (element.props?.name != null)
					objectMap.set(element.props.name, sprite);

			case 'sound':
				if (element.audio?.path != null)
					core.json.extensions.AudioData.AudioConfig.playElementAudio(element.audio, 'gameplay/stages/');
			default:
				Console.log('Element Type Unknown $type', true);
		}
	}

	public function getObject(name:String):FunkinSprite {
		return objectMap.get(name);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		if (vsliceScript != null)
			modding.vslice.VSliceHooks.call(vsliceScript, 'update', elapsed);
		#if HSCRIPT_ALLOWED
		if (stageScript.hasScripts)
			stageScript.call('onUpdate', [elapsed]);
		#end
	}

	public function onBeatHit(beat:Float):Void {
		for (el in elements) {
			if (Std.isOfType(el, funkin.play.stage.StageProp))
				cast(el, funkin.play.stage.StageProp).beatDance(beat);
		}
		for (char in extraChars)
			if (char.danceEvery <= 0 || beat % char.danceEvery == 0)
				char.dance();
		#if HSCRIPT_ALLOWED
		stageScript.call('onBeatHit', [beat]);
		#end
	}

	public function onStepHit(step:Int):Void {
		#if HSCRIPT_ALLOWED
		stageScript.call('onStepHit', [step]);
		#end
	}

	override public function destroy() {
		modding.vslice.VSliceHooks.unregister(vsliceScript);
		callVSlice('onDestroy', {});
		if (vsliceScript != null && funkin.play.PlayState.instance?.currentStage == vsliceScript)
			funkin.play.PlayState.instance.currentStage = null;
		vsliceScript = null;
		extraChars = null;
		#if HSCRIPT_ALLOWED
		stageScript.call('onDestroy', []);
		stageScript.destroy();
		stageScript = null;
		#end
		for (element in elements)
			element.destroy();
		elements = null;
		charProps = null;
		objectMap = null;
		charLayer.destroy();
		charLayer = null;
		super.destroy();
	}
}

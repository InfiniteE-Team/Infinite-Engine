package states;

// sprites idk, groups
import flixel.group.FlxGroup;
import core.assets.FunkinSprite;
// menu data
import core.json.engine.MenuData;
import core.json.engine.MenuData.Element;
import core.json.engine.MenuData.ElementType;
// audio data
import core.json.extensions.AudioData;
// tweens
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class MenuState extends MusicBeatState {
	public var menuData:MenuData;

	var _elementMap:Map<String, FlxBasic> = new Map();

	// input to keyboard or idk
	var _focusables:Array<Element> = [];
	var _focusIndex:Int = 0;

	public var menu:String = 'mainmenustate';

	final menu_folder:String = 'menus/$menu';

	public function new() {
		super();
	}

	override public function create():Void {
		super.create();

		menuData = UtilsData.readJson(Paths.getPath('data/$menu_folder', 'json'));
		if (menuData == null || menuData.elements == null) {
			Trace.traceOnce('MenuState: not found $menu_folder', true);
			return;
		}
		buildElements(menuData.elements, null);
	}

	function buildElements(elements:Array<Element>, parent:FlxGroup):Void {
		for (element in elements)
			buildElement(element, parent);
	}

	function buildElement(el:Element, parent:FlxGroup):Void {
		var obj:FlxBasic = null;

		switch (el.type) {
			case Sprite | Animated | Character:
				obj = buildSprite(el);

			case Graphic:
				obj = buildGraphic(el);

			case Group | CustomClassGroup:
				obj = buildGroup(el);

			case Sound:
				playElementAudio(el.audio);
				return;

			case CustomClass:
				obj = buildCustomClass(el);

			case _:
				Trace.traceOnce('MenuState: unknown type "${el.type}"', true);
				return;
		}

		if (obj == null)
			return;

		if (el.id != null)
			_elementMap.set(el.id, obj);

		if (el.props?.visible != null)
			(cast obj : Dynamic).visible = el.props.visible;

		if (el.camera != null)
			assignCamera(obj, el.camera);

		if (el.focusable == true)
			_focusables.push(el);

		if (parent != null)
			parent.add(obj);
		else
			add(obj);

		if (el.tweenIn != null)
			applyTweenIn(obj, el);
	}

	function buildSprite(el:Element):FunkinSprite {
		var spr = new FunkinSprite(0, 0);

		if (el.props != null)
			spr.loadProps(el.props, MENU_PATH);

		applyAnchor(spr, el);

		if (el.velocityX != null)
			spr.velocity.x = el.velocityX;
		if (el.velocityY != null)
			spr.velocity.y = el.velocityY;

		if (el.loopAnim != null)
			applyLoopAnim(spr, el.loopAnim);

		if (el.audio != null)
			playElementAudio(el.audio);

		return spr;
	}

	function buildGraphic(el:Element):FunkinSprite {
		var spr = new FunkinSprite(0, 0);

		if (el.props != null)
			spr.loadMakeGraphic(el.props);

		applyAnchor(spr, el);
		return spr;
	}

	function buildGroup(el:Element):FlxGroup {
		var group = new FlxGroup();

		if (el.props?.position != null) {}

		if (el.children != null)
			buildElements(el.children, group);

		return group;
	}

	function buildCustomClass(el:Element):FlxBasic {
		return buildSprite(el);
	}

	function playElementAudio(audio:AudioData):Void {
		if (audio == null)
			return;

		var isMusic = audio.channel == 'music' || audio.looped == true;

		if (isMusic) {
			FlxG.sound.playMusic(Paths.music(audio.path), audio.volume ?? 1.0, audio.looped ?? true);
			if (audio.fadeIn != null)
				FlxG.sound.music.fadeIn(audio.fadeIn, 0, audio.volume ?? 1.0);
		} else {
			var sfx = FlxG.sound.play(Paths.sound(audio.path), audio.volume ?? 1.0, audio.looped ?? false);
			if (sfx != null && audio.pitch != null)
				sfx.pitch = audio.pitch;
		}
	}

	function applyAnchor(spr:FunkinSprite, el:Element):Void {
		var ax = el.anchorX ?? 0.0;
		var ay = el.anchorY ?? 0.0;

		spr.x -= spr.width * ax;
		spr.y -= spr.height * ay;
	}

	function applyTweenIn(obj:FlxBasic, el:Element):Void {
		var tween = el.tweenIn;
		var delay = (el.startDelay ?? 0) + (t.delay ?? 0);
		var ease = utils.InfiniteUtil.resolveEase(t.ease);
		var spr:Dynamic = cast obj;

		switch (tween.type) {
			case 'fadeIn':
				spr.alpha = 0;
				FlxTween.tween(spr, {alpha: el.props?.alpha ?? 1.0}, t.duration, {ease: ease, startDelay: delay});

			case 'fadeOut':
				FlxTween.tween(spr, {alpha: 0}, t.duration, {ease: ease, startDelay: delay});

			case 'slideUp':
				var targetY = spr.y;
				spr.y += 80;
				spr.alpha = 0;
				FlxTween.tween(spr, {y: targetY, alpha: 1.0}, t.duration, {ease: ease, startDelay: delay});

			case 'slideDown':
				var targetY = spr.y;
				spr.y -= 80;
				spr.alpha = 0;
				FlxTween.tween(spr, {y: targetY, alpha: 1.0}, t.duration, {ease: ease, startDelay: delay});

			case 'slideLeft':
				var targetX = spr.x;
				spr.x += 80;
				spr.alpha = 0;
				FlxTween.tween(spr, {x: targetX, alpha: 1.0}, t.duration, {ease: ease, startDelay: delay});

			case 'slideRight':
				var targetX = spr.x;
				spr.x -= 80;
				spr.alpha = 0;
				FlxTween.tween(spr, {x: targetX, alpha: 1.0}, t.duration, {ease: ease, startDelay: delay});

			case 'scale':
				spr.scale.set(0, 0);
				spr.alpha = 0;
				var targetScale = {
					x: el.props?.scale[0] ?? 1.0,
					y: el.props?.scale[1] ?? 1.0
				};
				FlxTween.tween(spr.scale, targetScale, t.duration, {ease: ease, startDelay: delay});
				FlxTween.tween(spr, {alpha: 1.0}, t.duration * 0.5, {ease: ease, startDelay: delay});

			case _:
				Trace.traceOnce('MenuState: unknown tween type "${el.type}"', true);
		}
	}

	function applyLoopAnim(spr:FunkinSprite, loop:LoopAnimData):Void {
		switch (loop.type) {
			case 'floatY':
				var baseY = spr.y;
				FlxTween.tween(spr, {y: baseY - 10}, loop.duration * 0.5, {
					ease: FlxEase.sineInOut,
					type: loop.pingPong != false ? FlxTweenType.PINGPONG : FlxTweenType.LOOPING
				});

			case 'floatX':
				var baseX = spr.x;
				FlxTween.tween(spr, {x: baseX + 10}, loop.duration * 0.5, {
					ease: FlxEase.sineInOut,
					type: loop.pingPong != false ? FlxTweenType.PINGPONG : FlxTweenType.LOOPING
				});

			case 'pulse':
				FlxTween.tween(spr, {alpha: 0.4}, loop.duration * 0.5, {
					ease: FlxEase.sineInOut,
					type: FlxTweenType.PINGPONG
				});

			case 'rotate':
				FlxTween.angle(spr, spr.angle, spr.angle + 360, loop.duration, {type: FlxTweenType.LOOPING});

			case _:
				Trace.traceOnce('MenuState: frameLoop firstAnim + looped true', true);
		}
	}

	function assignCamera(obj:FlxBasic, camName:String):Void {
		// ex: if (camName == 'hud') obj.cameras = [camHUD];
	}

	public function getElementById(id:String):Null<FlxBasic>
		return _elementMap.get(id);

	// sprite registred cast
	public function getSpriteById(id:String):Null<FunkinSprite> {
		var obj = _elementMap.get(id);
		return (obj is FunkinSprite) ? cast obj : null;
	}

	// show elemnt with Tween
	public function showElement(id:String):Void {
		var obj = _elementMap.get(id);
		if (obj == null)
			return;
		(cast obj : Dynamic).visible = true;

		// relance the tween
		var el = findElementById(menuData.elements, id);
		if (el?.tweenIn != null)
			applyTweenIn(obj, el);
	}

	// tweenOut
	public function hideElement(id:String):Void {
		var el = findElementById(menuData.elements, id);
		var obj = _elementMap.get(id);
		if (obj == null || el == null)
			return;

		if (el.tweenOut != null) {
			var t = el.tweenOut;
			var ease = resolveEase(t.ease);
			var spr:Dynamic = cast obj;

			switch (t.type) {
				case 'fadeOut':
					FlxTween.tween(spr, {alpha: 0}, t.duration, {ease: ease, onComplete: _ -> spr.visible = false});
				case _:
					spr.visible = false;
			}
		} else {
			(cast obj : Dynamic).visible = false;
		}
	}

	function findElementById(elements:Array<Element>, id:String):Null<Element> {
		for (el in elements) {
			if (el.id == id)
				return el;
			if (el.children != null) {
				var found = findElementById(el.children, id);
				if (found != null)
					return found;
			}
		}
		return null;
	}

	// ACTIONS

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		handleInput();
	}

	function handleInput():Void {
		if (_focusables.length == 0)
			return;

		if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
			moveFocus(1);
		else if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W)
			moveFocus(-1);
		else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
			confirmFocus();
	}

	function moveFocus(dir:Int):Void {
		_focusIndex = (_focusIndex + dir + _focusables.length) % _focusables.length;
		var el = _focusables[_focusIndex];
		if (el.onHover != null)
			callAction(el.onHover, el);
	}

	function confirmFocus():Void {
		var el = _focusables[_focusIndex];
		if (el.onClick != null)
			callAction(el.onClick, el);
	}

	// action

	function callAction(action:String, el:Element):Void {
		// ex:
		// switch (action) {
		//     case 'onPlayPressed':  FlxG.switchState(new PlayState());
		//     case 'onButtonHover':  FlxG.sound.play(Paths.sound('hover'));
		// }
		Trace.traceOnce('MenuState: action not handler -> "$action"');
	}

	override public function destroy():Void {
		_elementMap = null;
		_focusables = null;
		super.destroy();
	}
}

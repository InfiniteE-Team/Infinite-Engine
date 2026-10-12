package modding.editors.ui;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import core.assets.FunkinSprite;

typedef TabEntry = {
	var label:String;
}

class SectionTab extends FlxSpriteGroup {
	public var activeIndex:Int = 0;

	var tabCount:Int;
	var tabW:Float;

	public var tabH:Float = 0;

	var gap:Float = 6;

	var totalWidth = 0.0;

	var activeSprite:FunkinSprite;
	var labels:Array<FlxText> = [];

	var cam:flixel.FlxCamera;
	var tweening:Bool = false;

	var onSelect:Int->Void;

	public function new(x:Float, y:Float, totalWidth:Float, tabH:Float, tabs:Array<TabEntry>, cam:flixel.FlxCamera, ?onSelect:Int->Void) {
		super(x, y);
		this.cam = cam;
		this.onSelect = onSelect;
		this.tabCount = tabs.length;
		this.gap = 6;
		this.tabH = tabH;
		this.totalWidth = totalWidth;
		this.tabW = (totalWidth - gap * (tabCount - 1)) / tabCount;
		this.scrollFactor.set(0, 0);

		build(tabs);
	}

	function getTabStartX(i:Int):Float {
		return i * (tabW + gap);
	}

	function getTabX(i:Int):Float {
		return getTabStartX(i) + (tabW * 0.5) - 40;
	}

	function build(tabs:Array<TabEntry>) {
		var dis = new FunkinSprite(0, 0, true);
		dis.frames = Paths.getPath('menus/editors/ui/cells', 'animated');
		dis.animation.addByNames('show', ['Cel DIS0000'], 1, false);
		dis.animation.play('show');
		dis.scale.x = (totalWidth / dis.frameWidth);
		dis.updateHitbox();
		tabH = dis.height;
		dis.antialiasing = SaveData.data.antialiasing;
		dis.scrollFactor.set(0, 0);
		dis.cameras = [cam];
		add(dis);

		activeSprite = new FunkinSprite(0, 0, true);
		activeSprite.frames = Paths.getPath('menus/editors/ui/cells', 'animated');
		activeSprite.animation.addByNames('show', ['Cel0000'], 1, false);
		activeSprite.animation.play('show');
		activeSprite.scale.x = (tabW / activeSprite.frameWidth) - 0.02;
		activeSprite.scale.y = 0.7;
		activeSprite.updateHitbox();
		activeSprite.x = getTabX(0);
		activeSprite.y = (tabH - activeSprite.height) * 0.5;
		activeSprite.antialiasing = SaveData.data.antialiasing;
		activeSprite.scrollFactor.set(0, 0);
		activeSprite.cameras = [cam];
		add(activeSprite);

		for (i in 0...tabs.length) {
			var lbl = new FlxText(getTabStartX(i), 0, tabW, tabs[i].label);
			lbl.setFormat(Paths.getPath('Funkin.otf', 'font'), 14, FlxColor.WHITE, 'center');
			lbl.y = (tabH - lbl.height) * 0.5;
			lbl.scrollFactor.set(0, 0);
			lbl.cameras = [cam];
			labels.push(lbl);
			add(lbl);
		}

        selectTab(0);
	}

	public function selectTab(index:Int) {
		if (index == activeIndex || tweening || index < 0 || index >= tabCount)
			return;

		activeIndex = index;
		tweening = true;

		FlxTween.tween(activeSprite, {x: getTabX(index)}, 0.15, {
			ease: FlxEase.quadOut,
			onComplete: (_) -> {
				tweening = false;
				if (onSelect != null)
					onSelect(index);
			}
		});
	}

	public function handleInput() {
		if (!FlxG.mouse.justPressed)
			return;

		var m = FlxG.mouse.getViewPosition(cam);
		var lx = m.x - this.x;
		var ly = m.y - this.y;

		if (ly < 0 || ly > tabH)
			return;

		for (i in 0...tabCount) {
			var tx = getTabStartX(i);
			if (lx >= tx && lx < tx + tabW) {
				selectTab(i);
				break;
			}
		}
	}
}

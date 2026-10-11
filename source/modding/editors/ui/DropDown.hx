package modding.editors.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;

class DropDown extends FlxSpriteGroup {
	var header:FlxSprite;
	var header2:FlxSprite;
	var headerLabel:FlxText;
	var itemList:Array<{bg:FlxSprite, label:FlxText}> = [];

	var options:Array<String> = [];
	var isOpen:Bool = false;
	var selectedIndex:Int = 0;

	var cam:game.objects.Camera;
	var onChangeCallback:String->Void;

	static final SCALE:Float = 0.5;
	static final ITEM_H:Float = 51 * SCALE;

	public function new(x:Float, y:Float, optionInit:String, options:Array<String>, ?onChange:String->Void, ?cam:game.objects.Camera) {
		super(x, y);

		this.options = options;
		this.cam = cam;
		this.onChangeCallback = onChange;

		header2 = new FlxSprite();
		header2.frames = Paths.getPath('menus/editors/ui/dropDown', 'animated');
		header2.animation.addByPrefix('idle', 'contentNames', 24, true);
		header2.animation.play('idle');
		header2.scale.set(SCALE, SCALE);
		header2.updateHitbox();
		add(header2);

		header = new FlxSprite(header2.width + 5);
		header.frames = Paths.getPath('menus/editors/ui/dropDown', 'animated');
		header.animation.addByPrefix('idle', 'pageDown', 24, true);
		header.animation.play('idle');
		header.scale.set(SCALE, SCALE);
		header.updateHitbox();
		add(header);

		headerLabel = new FlxText(header2.x + 5, 0, 150, options.length > 0 ? optionInit : '');
		headerLabel.setFormat(null, 14, FlxColor.WHITE, 'left');
		headerLabel.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
		headerLabel.y = (header.height / 2) - (headerLabel.height / 2);
		add(headerLabel);

		for (i in 0...options.length) {
			var itemY = header.height + (i * ITEM_H);

			var bg = new FlxSprite(0, itemY);
			bg.frames = Paths.getPath('menus/editors/ui/dropDown', 'animated');
			bg.animation.addByPrefix('idle', 'contentNames', 24, true);
			bg.animation.play('idle');
			bg.scale.set(SCALE, SCALE);
			bg.updateHitbox();
			bg.visible = false;
			add(bg);

			var label = new FlxText(8, itemY + (ITEM_H - 14) / 2, bg.width - 10, options[i]);
			label.setFormat(null, 13, FlxColor.WHITE, 'left');
			label.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1);
			label.visible = false;
			add(label);

			itemList.push({bg: bg, label: label});
		}
	}

	public function setOptions(options:Array<String>) {
		this.options = options;
		for (i in 0...itemList.length) {
			itemList[i].label.text = i < options.length ? options[i] : '';
		}
		selectedIndex = 0;
		headerLabel.text = options.length > 0 ? options[0] : '';
		close();
	}

	public function getSelected():String {
		return options.length > 0 ? options[selectedIndex] : '';
	}

	function open() {
		isOpen = true;
		for (item in itemList) {
			item.bg.visible = true;
			item.label.visible = true;
		}
	}

	function close() {
		isOpen = false;
		for (item in itemList) {
			item.bg.visible = false;
			item.label.visible = false;
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var mouse = FlxG.mouse.getViewPosition(cam != null ? cam : FlxG.camera);
		var mx = mouse.x;
		var my = mouse.y;

		var onHeader = mx >= header.x && mx <= header.x + header.width && my >= header.y && my <= header.y + header.height;
		if (onHeader && FlxG.mouse.justPressed)
			isOpen ? close() : open();

		if (isOpen) {
			for (i in 0...itemList.length) {
				var item = itemList[i];
				var iy = y + header.height + i * ITEM_H;
				var onItem = mx >= x && mx <= x + item.bg.width && my >= iy && my <= iy + ITEM_H;

				item.bg.color = onItem ? 0xFF880020 : FlxColor.WHITE;

				if (onItem && FlxG.mouse.justPressed) {
					selectedIndex = i;
					headerLabel.text = options[i];
					if (onChangeCallback != null)
						onChangeCallback(options[i]);
					close();
				}
			}
		}
	}
}

package modding.editors.gameplay;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;

class EditorWidgets {
	public static final CARD_FILL:Int = 0xFF461546;
	public static final CARD_BORDER:Int = 0xFF333349;
	public static final MUTED:Int = 0xFF8585A3;
	public static final ACCENT:Int = 0xFFFFD866;
	public static final GOOD:Int = 0xFF7DFF9A;

	public static function card(x:Float, y:Float, w:Int, h:Int, ?cam:flixel.FlxCamera):FlxSprite {
		var bmp = new BitmapData(w, h, true, CARD_BORDER);
		bmp.fillRect(new Rectangle(1, 1, w - 2, h - 2), CARD_FILL);

		var spr = new FlxSprite(x, y);
		spr.loadGraphic(bmp);
		spr.scrollFactor.set(0, 0);
		spr.active = false;
		if (cam != null)
			spr.cameras = [cam];
		return spr;
	}

	public static function frame(x:Float, y:Float, w:Int, h:Int, thickness:Int, color:Int, cam:flixel.FlxCamera):Array<FlxSprite> {
		var parts:Array<FlxSprite> = [];
		var rects:Array<Array<Float>> = [
			[x - thickness, y - thickness, w + thickness * 2, thickness],
			[x - thickness, y + h, w + thickness * 2, thickness],
			[x - thickness, y, thickness, h],
			[x + w, y, thickness, h]
		];
		for (r in rects) {
			var spr = new FlxSprite(r[0], r[1]).makeGraphic(Std.int(r[2]), Std.int(r[3]), color);
			spr.scrollFactor.set(0, 0);
			spr.active = false;
			spr.cameras = [cam];
			parts.push(spr);
		}
		return parts;
	}

	public static function eventAbbreviation(name:String):String {
		if (name == null || name == '')
			return '?';

		var out:String = '';
		for (i in 0...name.length) {
			var c = name.charAt(i);
			if (c != c.toLowerCase() && c != ' ')
				out += c;
		}
		if (out.length < 2)
			out = name.substr(0, 2).toUpperCase();
		return out.substr(0, 3);
	}

	public static function eventColor(name:String):Int {
		var palette:Array<Int> = [
			0xFF3B82F6,
			0xFF22A06B,
			0xFFD97706,
			0xFFC026D3,
			0xFFDC2626,
			0xFF0891B2,
			0xFF7C3AED
		];
		var hash:Int = 0;
		var text:String = name ?? '';
		for (i in 0...text.length) {
			var code:Int = text.charCodeAt(i);
			hash = (hash * 31 + code) & 0xFFFF;
		}
		return palette[hash % palette.length];
	}
}

class TextPrompt {
	public var active(default, null):Bool = false;

	public var justClosed:Bool = false;

	public var text:String = '';
	public var label:String = '';

	var onDone:String->Void = null;
	var onCancel:Void->Void = null;

	var savedMuteKeys:Array<flixel.input.keyboard.FlxKey> = null;
	var savedVolumeUpKeys:Array<flixel.input.keyboard.FlxKey> = null;
	var savedVolumeDownKeys:Array<flixel.input.keyboard.FlxKey> = null;

	public function new() {}

	public function open(label:String, initial:String, onDone:String->Void, ?onCancel:Void->Void):Void {
		close(false);

		this.label = label;
		this.text = initial ?? '';
		this.onDone = onDone;
		this.onCancel = onCancel;
		active = true;

		savedMuteKeys = FlxG.sound.muteKeys;
		savedVolumeUpKeys = FlxG.sound.volumeUpKeys;
		savedVolumeDownKeys = FlxG.sound.volumeDownKeys;
		FlxG.sound.muteKeys = null;
		FlxG.sound.volumeUpKeys = null;
		FlxG.sound.volumeDownKeys = null;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
	}

	public function close(markClosed:Bool = true):Void {
		if (!active)
			return;

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
		FlxG.sound.muteKeys = savedMuteKeys;
		FlxG.sound.volumeUpKeys = savedVolumeUpKeys;
		FlxG.sound.volumeDownKeys = savedVolumeDownKeys;
		active = false;
		onDone = null;
		onCancel = null;

		if (markClosed)
			justClosed = true;
	}

	function onKey(e:KeyboardEvent):Void {
		switch (e.keyCode) {
			case 13 | 108:
				var done = onDone;
				var value = text;
				close();
				if (done != null)
					done(value);
			case 27:
				var cancel = onCancel;
				close();
				if (cancel != null)
					cancel();
			case 8:
				if (text.length > 0)
					text = text.substr(0, text.length - 1);
			default:
				if (e.ctrlKey || e.commandKey)
					return;
				if (e.charCode >= 32 && e.charCode != 127 && text.length < 40)
					text += String.fromCharCode(e.charCode);
		}
	}
}

typedef PanelRow = {
	var label:String;
	var value:String;
	var ?arrows:Bool;
	var ?buttons:Array<String>;
	var ?dim:Bool;
	var ?wide:Bool;
}

typedef PanelRowView = {
	var bg:FlxSprite;
	var label:FlxText;
	var left:FlxText;
	var value:FlxText;
	var right:FlxText;
	var btnBg:Array<FlxSprite>;
	var btn:Array<FlxText>;
}

class OptionPanel extends FlxGroup {
	public static final ROW_H:Int = 28;
	static final BTN_W:Int = 64;
	static final BTN_AREA:Int = 150;

	var cam:flixel.FlxCamera;
	var boxX:Float;
	var boxY:Float;
	var boxW:Float;
	var boxH:Float = 0;
	var firstRowY:Float = 0;

	var bg:FlxSprite;
	var titleText:FlxText;
	var hintText:FlxText;
	var footerText:FlxText;
	var views:Array<PanelRowView> = [];
	var rowCount:Int = 0;
	var rowInfo:Array<PanelRow> = [];

	public var isOpen(default, null):Bool = false;

	public function new(x:Float, y:Float, width:Float, cam:flixel.FlxCamera) {
		super();
		this.cam = cam;
		boxX = x;
		boxY = y;
		boxW = width;

		bg = new FlxSprite(x, y).makeGraphic(1, 1, 0xF2111118);
		place(bg);
		bg.visible = false;

		titleText = text(x + 16, y + 10, width - 32, 15, FlxColor.WHITE);
		hintText = text(x + 16, y + 32, width - 32, 11, EditorWidgets.MUTED);
		footerText = text(x + 16, y + 40, width - 32, 12, EditorWidgets.MUTED);
	}

	function place(s:flixel.FlxObject):Void {
		s.scrollFactor.set(0, 0);
		s.cameras = [cam];
		add(s);
	}

	function text(x:Float, y:Float, w:Float, size:Int, color:Int):FlxText {
		var t = new FlxText(x, y, w, '', size);
		t.setFormat(null, size, color, LEFT, OUTLINE, FlxColor.BLACK);
		place(t);
		t.visible = false;
		return t;
	}

	function makeRow():PanelRowView {
		var row:PanelRowView = {
			bg: new FlxSprite(boxX + 8, 0).makeGraphic(Std.int(boxW - 16), ROW_H - 2, 0xFFFFFFFF),
			label: text(boxX + 16, 0, boxW * 0.36, 13, FlxColor.WHITE),
			left: text(0, 0, 20, 15, EditorWidgets.ACCENT),
			value: text(0, 0, 100, 13, 0xFFE4E4EE),
			right: text(0, 0, 20, 15, EditorWidgets.ACCENT),
			btnBg: [],
			btn: []
		};
		place(row.bg);
		row.bg.visible = false;

		remove(row.bg, true);
		insert(members.indexOf(row.label), row.bg);

		for (i in 0...2) {
			var b = new FlxSprite(0, 0).makeGraphic(BTN_W, ROW_H - 8, 0xFF3C3C58);
			place(b);
			b.visible = false;
			row.btnBg.push(b);

			var t = text(0, 0, BTN_W, 11, FlxColor.WHITE);
			t.alignment = flixel.text.FlxText.FlxTextAlign.CENTER;
			row.btn.push(t);
		}
		return row;
	}

	function valueX():Float {
		return boxX + boxW * 0.40;
	}

	function valueW():Float {
		return boxW - boxW * 0.40 - 16 - BTN_AREA;
	}

	function buttonX(i:Int, count:Int):Float {
		var edge:Float = boxX + boxW - 14;
		return edge - (count - i) * (BTN_W + 6) + 6;
	}

	public function show(title:String, hint:String, rows:Array<PanelRow>, selected:Int, footer:String):Void {
		rowInfo = rows;
		rowCount = rows.length;
		while (views.length < rowCount)
			views.push(makeRow());

		titleText.text = title;
		hintText.text = hint;
		titleText.visible = true;
		hintText.visible = hint != '';

		firstRowY = boxY + 34 + (hint != '' ? hintText.height + 6 : 0);

		for (i in 0...views.length) {
			var v = views[i];
			if (i >= rowCount) {
				setRowVisible(v, false);
				continue;
			}

			var r = rows[i];
			var y:Float = firstRowY + i * ROW_H;
			var wide:Bool = r.wide == true;
			var arrows:Bool = r.arrows == true;
			var buttons:Array<String> = r.buttons ?? [];

			setRowVisible(v, true);
			v.bg.setPosition(boxX + 8, y);
			v.bg.color = i == selected ? 0xFF3A3A5C : 0xFF20202C;

			setWidth(v.label, wide ? boxW - 32 : boxW * 0.36);
			v.label.text = r.label;
			v.label.color = r.dim == true ? EditorWidgets.MUTED : FlxColor.WHITE;
			v.label.setPosition(boxX + 16, y + 5);

			v.left.visible = arrows && !wide;
			v.right.visible = arrows && !wide;
			v.left.text = '<';
			v.right.text = '>';
			v.left.setPosition(valueX(), y + 4);
			v.right.setPosition(valueX() + valueW() - 14, y + 4);

			v.value.visible = !wide;
			setWidth(v.value, arrows ? valueW() - 40 : valueW());
			var align:flixel.text.FlxText.FlxTextAlign = arrows ? CENTER : LEFT;
			if (v.value.alignment != align)
				v.value.alignment = align;
			v.value.text = r.value;
			v.value.setPosition(valueX() + (arrows ? 20 : 0), y + 5);

			for (b in 0...2) {
				var on:Bool = b < buttons.length && !wide;
				v.btnBg[b].visible = on;
				v.btn[b].visible = on;
				if (on) {
					v.btn[b].text = buttons[b];
					v.btnBg[b].setPosition(buttonX(b, buttons.length), y + 4);
					v.btn[b].setPosition(buttonX(b, buttons.length), y + 8);
				}
			}
		}

		footerText.text = footer;
		footerText.visible = footer != '';
		var footerY:Float = firstRowY + rowCount * ROW_H + 6;
		footerText.setPosition(boxX + 16, footerY);

		boxH = footerY - boxY + (footer != '' ? footerText.height : 0) + 12;
		bg.setGraphicSize(Std.int(boxW), Std.int(boxH));
		bg.updateHitbox();
		bg.setPosition(boxX, boxY);
		bg.visible = true;
		isOpen = true;
	}

	// show() runs every frame and these setters redraw the text even if nothing changed -JloorDev
	static function setWidth(t:FlxText, w:Float):Void {
		if (t.fieldWidth != w)
			t.fieldWidth = w;
	}

	function setRowVisible(v:PanelRowView, on:Bool):Void {
		v.bg.visible = on;
		v.label.visible = on;
		v.left.visible = on;
		v.value.visible = on;
		v.right.visible = on;
		for (i in 0...2) {
			v.btnBg[i].visible = on;
			v.btn[i].visible = on;
		}
	}

	public function hide():Void {
		bg.visible = false;
		titleText.visible = false;
		hintText.visible = false;
		footerText.visible = false;
		for (v in views)
			setRowVisible(v, false);
		rowCount = 0;
		isOpen = false;
	}

	public function contains(mx:Float, my:Float):Bool {
		return isOpen && mx >= boxX && mx < boxX + boxW && my >= boxY && my < boxY + boxH;
	}

	public function hit(mx:Float, my:Float):{row:Int, part:Int} {
		if (!isOpen || mx < boxX || mx >= boxX + boxW)
			return {row: -1, part: 0};

		for (i in 0...rowCount) {
			var y:Float = firstRowY + i * ROW_H;
			if (my < y || my >= y + ROW_H)
				continue;

			var r = rowInfo[i];
			if (r.wide != true) {
				var vx:Float = valueX();
				if (r.arrows == true) {
					if (mx >= vx - 4 && mx < vx + 24)
						return {row: i, part: 1};
					if (mx >= vx + valueW() - 24 && mx < vx + valueW() + 4)
						return {row: i, part: 2};
				}

				var buttons:Array<String> = r.buttons ?? [];
				for (b in 0...buttons.length) {
					var bx:Float = buttonX(b, buttons.length);
					if (mx >= bx && mx < bx + BTN_W)
						return {row: i, part: 3 + b};
				}
			}
			return {row: i, part: 0};
		}
		return {row: -1, part: 0};
	}
}

typedef MenuItem = {
	var label:String;
	var ?shortcut:String;
	var ?action:Void->Void;
	var ?checked:Void->Bool;
	var ?separator:Bool;
}

typedef MenuDef = {
	var title:String;
	var items:Void->Array<MenuItem>;
}

class MenuBar extends FlxGroup {
	public static final HEIGHT:Int = 26;
	static final ROW_H:Int = 24;
	static final SEPARATOR_H:Int = 9;
	static final MIN_DROP_W:Int = 220;

	var dropW:Int = 220;

	var cam:flixel.FlxCamera;
	var menus:Array<MenuDef>;
	var tabX:Array<Float> = [];
	var tabW:Array<Float> = [];
	var tabBg:Array<FlxSprite> = [];
	var rightText:FlxText;
	var dropGroup:FlxGroup;

	var current:Array<MenuItem> = [];
	var rowTop:Array<Float> = [];
	var rowHeight:Array<Float> = [];
	var rowBg:Array<FlxSprite> = [];
	var openIndex:Int = -1;
	var hoverTab:Int = -1;
	var hoverRow:Int = -1;
	var dropX:Float = 0;
	var dropH:Float = 0;

	public var isOpen(get, never):Bool;

	function get_isOpen():Bool
		return openIndex >= 0;

	public function new(menus:Array<MenuDef>, cam:flixel.FlxCamera) {
		super();
		this.menus = menus;
		this.cam = cam;

		place(flixel.util.FlxGradient.createGradientFlxSprite(FlxG.width, HEIGHT, [0xFF461546, 0xFF030320], 1, 90));
		place(new FlxSprite(0, HEIGHT - 1).makeGraphic(FlxG.width, 1, EditorWidgets.CARD_BORDER));

		var x:Float = 6;
		var labels:Array<FlxText> = [];
		for (m in menus) {
			var label = new FlxText(x + 10, 5, 0, m.title, 13);
			label.setFormat(null, 13, FlxColor.WHITE, LEFT);
			var w:Float = label.width + 20;

			var bgSprite = new FlxSprite(x, 0).makeGraphic(Std.int(w), HEIGHT - 1, 0xFF34344A);
			bgSprite.visible = false;
			place(bgSprite);
			place(label);

			tabX.push(x);
			tabW.push(w);
			tabBg.push(bgSprite);
			labels.push(label);
			x += w;
		}

		rightText = new FlxText(0, 6, FlxG.width - 12, '', 12);
		rightText.setFormat(null, 12, EditorWidgets.MUTED, RIGHT);
		place(rightText);

		dropGroup = new FlxGroup();
		add(dropGroup);
	}

	function place(s:flixel.FlxObject):Void {
		s.scrollFactor.set(0, 0);
		s.cameras = [cam];
		add(s);
	}

	function placeDrop(s:flixel.FlxObject):Void {
		s.scrollFactor.set(0, 0);
		s.cameras = [cam];
		dropGroup.add(s);
	}

	public function setRightText(text:String):Void {
		if (rightText.text != text)
			rightText.text = text;
	}

	function tabAt(mx:Float):Int {
		for (i in 0...tabX.length) {
			if (mx >= tabX[i] && mx < tabX[i] + tabW[i])
				return i;
		}
		return -1;
	}

	function inDrop(mx:Float, my:Float):Bool {
		return isOpen && mx >= dropX && mx < dropX + dropW && my >= HEIGHT && my < HEIGHT + dropH;
	}

	function rowAt(mx:Float, my:Float):Int {
		if (!inDrop(mx, my))
			return -1;
		for (i in 0...current.length) {
			var top:Float = HEIGHT + rowTop[i];
			if (my >= top && my < top + rowHeight[i])
				return current[i].separator == true ? -1 : i;
		}
		return -1;
	}

	public function contains(mx:Float, my:Float):Bool {
		return my < HEIGHT || inDrop(mx, my);
	}

	function openMenu(i:Int):Void {
		clearDrop();
		openIndex = i;
		current = menus[i].items();

		var widest:Float = 0;
		for (item in current) {
			if (item.separator == true)
				continue;
			var prefix:String = item.checked != null ? '[x] ' : '';
			var l = new FlxText(0, 0, 0, prefix + item.label, 13);
			var k = new FlxText(0, 0, 0, item.shortcut ?? '', 11);
			var need:Float = l.width + (item.shortcut != null ? k.width + 36 : 0) + 28;
			l.destroy();
			k.destroy();
			if (need > widest)
				widest = need;
		}
		dropW = Std.int(Math.max(MIN_DROP_W, Math.min(widest, FlxG.width - 12)));

		dropX = Math.min(tabX[i], FlxG.width - dropW - 4);
		var y:Float = 4;
		for (item in current) {
			var h:Float = item.separator == true ? SEPARATOR_H : ROW_H;
			rowTop.push(y);
			rowHeight.push(h);
			y += h;
		}
		dropH = y + 4;

		placeDrop(new FlxSprite(dropX - 1, HEIGHT - 1).makeGraphic(dropW + 2, Std.int(dropH) + 2, EditorWidgets.CARD_BORDER));
		placeDrop(new FlxSprite(dropX, HEIGHT).makeGraphic(dropW, Std.int(dropH), 0xFA1B1B26));

		for (r in 0...current.length) {
			var item = current[r];
			var top:Float = HEIGHT + rowTop[r];

			if (item.separator == true) {
				placeDrop(new FlxSprite(dropX + 8, top + 4).makeGraphic(dropW - 16, 1, EditorWidgets.CARD_BORDER));
				rowBg.push(null);
				continue;
			}

			var hl = new FlxSprite(dropX + 3, top).makeGraphic(dropW - 6, ROW_H, 0xFF34344A);
			hl.visible = false;
			placeDrop(hl);
			rowBg.push(hl);

			var enabled:Bool = item.action != null;
			var prefix:String = '';
			if (item.checked != null)
				prefix = item.checked() ? '[x] ' : '[ ] ';

			var label = new FlxText(dropX + 12, top + 4, 0, prefix + item.label, 13);
			label.setFormat(null, 13, enabled ? FlxColor.WHITE : EditorWidgets.MUTED, LEFT);
			placeDrop(label);

			if (item.shortcut != null) {
				var key = new FlxText(dropX + dropW - 128, top + 6, 118, item.shortcut, 11);
				key.setFormat(null, 11, EditorWidgets.MUTED, RIGHT);
				placeDrop(key);
			}
		}
		updateTabs();
	}

	function clearDrop():Void {
		for (m in dropGroup.members) {
			if (m != null)
				m.destroy();
		}
		dropGroup.clear();
		current = [];
		rowTop = [];
		rowHeight = [];
		rowBg = [];
		hoverRow = -1;
	}

	public function close():Void {
		openIndex = -1;
		clearDrop();
		updateTabs();
	}

	function updateTabs():Void {
		for (i in 0...tabBg.length)
			tabBg[i].visible = i == openIndex || i == hoverTab;
	}

	public function hover(mx:Float, my:Float):Void {
		hoverTab = my < HEIGHT ? tabAt(mx) : -1;

		if (isOpen && hoverTab >= 0 && hoverTab != openIndex)
			openMenu(hoverTab);
		updateTabs();

		var row:Int = rowAt(mx, my);
		if (row != hoverRow) {
			if (hoverRow >= 0 && hoverRow < rowBg.length && rowBg[hoverRow] != null)
				rowBg[hoverRow].visible = false;
			hoverRow = row;
			if (row >= 0 && current[row].action != null && rowBg[row] != null)
				rowBg[row].visible = true;
		}
	}

	public function click(mx:Float, my:Float):Bool {
		if (my < HEIGHT) {
			var tab:Int = tabAt(mx);
			if (tab >= 0 && tab != openIndex)
				openMenu(tab);
			else
				close();
			return true;
		}

		if (isOpen) {
			var row:Int = rowAt(mx, my);
			if (row >= 0 && current[row].action != null) {
				var action = current[row].action;
				close();
				action();
			} else if (!inDrop(mx, my))
				close();
			return true;
		}

		return false;
	}
}

class InfoHUD extends flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxBasic> {
	static final CAPTIONS:Array<String> = ['TIME', 'STEP', 'BEAT', 'BPM'];

	var values:Array<FlxText> = [];

	public function new(x:Float = 0, y:Float = 0, width:Int = 360) {
		super();

		add(EditorWidgets.card(x, y, width, 44));

		var colW:Float = width / CAPTIONS.length;
		for (i in 0...CAPTIONS.length) {
			var cx:Float = x + 12 + i * colW;

			var caption = new FlxText(cx, y + 5, colW - 8, CAPTIONS[i], 10);
			caption.setFormat(null, 10, EditorWidgets.MUTED, LEFT);
			caption.scrollFactor.set(0, 0);
			add(caption);

			var value = new FlxText(cx, y + 19, colW - 8, '', 18);
			value.setFormat(null, 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			value.scrollFactor.set(0, 0);
			add(value);
			values.push(value);
		}
	}

	public function updateInfoText(songPosition:Float, stepInMs:Float, bpm:Float) {
		var seconds:Float = songPosition / 1000.0;
		var step:Int = Std.int(songPosition / stepInMs);
		var beat:Int = step >> 2;

		values[0].text = flixel.util.FlxStringUtil.formatTime(seconds, true);
		values[1].text = Std.string(step);
		values[2].text = Std.string(beat);
		values[3].text = Std.string(bpm);
	}
}

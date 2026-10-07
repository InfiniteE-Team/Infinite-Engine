package modding.editors.gameplay;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;

class EditorWidgets {
	public static final CARD_FILL:Int = 0xE6171720;
	public static final CARD_BORDER:Int = 0xFF3C3C4C;
	public static final MUTED:Int = 0xFF8C8CA0;
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
		var palette:Array<Int> = [0xFF3B82F6, 0xFF22A06B, 0xFFD97706, 0xFFC026D3, 0xFFDC2626, 0xFF0891B2, 0xFF7C3AED];
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

class OptionPanel extends FlxGroup {
	var bg:FlxSprite;
	var label:FlxText;
	var boxX:Float;
	var boxY:Float;
	var boxW:Float;

	public var isOpen(default, null):Bool = false;

	public function new(x:Float, y:Float, width:Float, cam:flixel.FlxCamera) {
		super();
		boxX = x;
		boxY = y;
		boxW = width;

		bg = new FlxSprite(x, y).makeGraphic(1, 1, 0xEE111111);
		bg.scrollFactor.set(0, 0);
		bg.cameras = [cam];
		bg.visible = false;
		add(bg);

		label = new FlxText(x + 14, y + 12, width - 28, '', 14);
		label.setFormat(null, 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		label.scrollFactor.set(0, 0);
		label.cameras = [cam];
		label.visible = false;
		add(label);
	}

	public function show(lines:Array<String>):Void {
		label.text = lines.join('\n');

		bg.setGraphicSize(Std.int(boxW), Std.int(label.height + 24));
		bg.updateHitbox();
		bg.setPosition(boxX, boxY);

		bg.visible = true;
		label.visible = true;
		isOpen = true;
	}

	public function hide():Void {
		bg.visible = false;
		label.visible = false;
		isOpen = false;
	}
}

class ViewToggles extends FlxGroup {
	static final CELL_W:Int = 112;
	static final CELL_H:Int = 22;

	var cells:Array<{x:Float, y:Float, mark:FlxSprite}> = [];
	var states:Array<Bool>;

	public var onChange:Void->Void = null;

	public function new(x:Float, y:Float, columns:Int, labels:Array<String>, states:Array<Bool>, cam:flixel.FlxCamera) {
		super();
		this.states = states;

		for (i in 0...labels.length) {
			var cx:Float = x + (i % columns) * CELL_W;
			var cy:Float = y + Std.int(i / columns) * CELL_H;

			var frame = new FlxSprite(cx, cy + 3).makeGraphic(14, 14, 0xFFFFFFFF);
			var inner = new FlxSprite(cx + 1, cy + 4).makeGraphic(12, 12, 0xFF222222);
			var mark = new FlxSprite(cx + 3, cy + 6).makeGraphic(8, 8, 0xFF66FF66);
			mark.visible = states[i];

			var text = new FlxText(cx + 20, cy + 2, CELL_W - 22, labels[i], 12);
			text.setFormat(null, 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);

			for (s in [cast(frame, flixel.FlxObject), inner, mark, text]) {
				s.scrollFactor.set(0, 0);
				s.cameras = [cam];
				add(s);
			}

			cells.push({x: cx, y: cy, mark: mark});
		}
	}

	public function get(i:Int):Bool {
		return states[i];
	}

	public function set(i:Int, value:Bool):Void {
		states[i] = value;
		cells[i].mark.visible = value;
	}

	public function click(mx:Float, my:Float):Bool {
		for (i in 0...cells.length) {
			var c = cells[i];
			if (mx >= c.x && mx < c.x + CELL_W - 4 && my >= c.y && my < c.y + CELL_H) {
				set(i, !states[i]);
				if (onChange != null)
					onChange();
				return true;
			}
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
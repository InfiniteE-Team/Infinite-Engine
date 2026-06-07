package utils;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;

class Trace {
	static var textGroup:FlxSpriteGroup;
	static var messages:Array<{text:String, color:Int}> = [];

	public static function init() {
		if (textGroup != null)
			return;
		textGroup = new FlxSpriteGroup();
		textGroup.scrollFactor.set(0, 0);
		textGroup.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		FlxG.state.add(textGroup);
	}

	public static function traceOnce(text:String, ?isError:Bool = false) {
		if (textGroup == null)
			init();

		var color = isError ? 0xFFFF0000 : 0xFFFFFFFF;

		for (m in messages)
			if (m.text == text)
				return;

		messages.push({text: text, color: color});
		if (messages.length > 10)
			messages.shift();

		refreshDisplay();
		trace(text);
	}

	static function refreshDisplay() {
		textGroup.clear();

		var yOffset = 10.0;
		for (msg in messages) {
			var t = new FlxText(10, yOffset, 0, msg.text, 12);
			t.setFormat(null, 12, msg.color, "left", OUTLINE, 0xFF000000);
			textGroup.add(t);
			yOffset += 15;
		}
	}

	public static function clear() {
        messages = [];
    }
}

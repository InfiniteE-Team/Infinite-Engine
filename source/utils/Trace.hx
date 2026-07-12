package utils;

import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

class Trace {
	static var textGroup:FlxSpriteGroup;
	static var messages:Array<{
		text:String,
		color:Int,
		timer:FlxTimer,
		label:FlxText
	}> = [];
	static final DURATION:Float = 7.0;

	public static function init() {
		textGroup = new FlxSpriteGroup();
		textGroup.scrollFactor.set(0, 0);
		textGroup.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		if (textGroup != null || FlxG.state != null)
			FlxG.state.add(textGroup);
	}

	public static function traceOnce(text:String, ?isError:Bool = false) {
		if (textGroup != null || textGroup.members == null)
			textGroup = null;
		if (textGroup == null)
			init();

		var color = isError ? 0xFFFF0000 : 0xFFFFFFFF;

		for (m in messages) {
			if (m.text == text) {
				m.timer.reset(DURATION);
				return;
			}
		}

		var entry:{
			text:String,
			color:Int,
			timer:FlxTimer,
			label:FlxText
		} = {
			text: text,
			color: color,
			timer: null,
			label: null
		};

		var yOffset = 10.0 + messages.length * 15;
		var label = new FlxText(10, yOffset, 0, text, 12);
		label.setFormat(null, 12, color, "left", OUTLINE, 0xFF000000);
		label.alpha = 0;
		textGroup.add(label);
		entry.label = label;

		// fade in
		FlxTween.tween(label, {alpha: 1}, 0.2);

		// fade out
		entry.timer = new FlxTimer().start(DURATION, (_) -> {
			FlxTween.tween(label, {alpha: 0}, 0.5, {
				onComplete: (_) -> {
					messages.remove(entry);
					textGroup.remove(label, true);
					label.destroy();
					refreshDisplay();
				}
			});
		});

		messages.push(entry);
		if (messages.length > 10)
			messages.shift();

		trace(text);
	}

	static function refreshDisplay() {
		textGroup.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		var yOffset = 10.0;
		for (m in messages) {
			if (m.label != null) {
				FlxTween.tween(m.label, {y: yOffset}, 0.15);
				yOffset += 15;
			}
		}
	}

	public static function clear() {
		messages = [];
	}
}

package utils;

import flixel.tweens.FlxEase;

class InfiniteUtil {
	public static function updateFramerate() {
		FlxG.updateFramerate = core.config.SaveData.data.framerate;
		FlxG.drawFramerate = core.config.SaveData.data.framerate;
	}

	public static function resolveEase(name:Null<String>):Float->Float {
		return switch (name ?? 'linear') {
			case 'easeIn': FlxEase.quadIn;
			case 'easeOut': FlxEase.quadOut;
			case 'easeInOut': FlxEase.quadInOut;
			case 'easeOutBack': FlxEase.backOut;
			case 'elasticOut': FlxEase.elasticOut;
			case 'bounceOut': FlxEase.bounceOut;
			case 'sineIn': FlxEase.sineIn;
			case 'sineOut': FlxEase.sineOut;
			case 'sineInOut': FlxEase.sineInOut;
			case "cubeOut": FlxEase.cubeOut;
			case "quartOut": FlxEase.quartOut;
			default: FlxEase.linear;
		}
	}
}

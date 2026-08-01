package utils;

import flixel.tweens.FlxEase;

class InfiniteUtil {
	public static function formatNumber(number:Int):String {
        var isNegative:Bool = number < 0;
        var absNumber:Int = isNegative ? -number : number;
        var str = Std.string(absNumber);
        var len = str.length;
        if (len <= 3) return (isNegative ? "-" : "") + str;
        
        var formatted = "";
        var count = 0;
        for (i in 0...len) {
            var charIndex = len - 1 - i;
            if (count > 0 && count % 3 == 0) {
                formatted = "," + formatted;
            }
            formatted = str.charAt(charIndex) + formatted;
            count++;
        }
        
        return (isNegative ? "-" : "") + formatted;
    }

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

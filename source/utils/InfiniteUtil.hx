package utils;

import flixel.tweens.FlxEase;

class InfiniteUtil {
	public static function formatNumber(number:Int):String {
		var isNegative:Bool = number < 0;
		var absNumber:Int = isNegative ? -number : number;
		var str = Std.string(absNumber);
		var len = str.length;
		if (len <= 3)
			return (isNegative ? "-" : "") + str;

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

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpDecay(base, target, deltaTime, -duration / logBase(2, precision))`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param duration Time in seconds to reach `target` within `precision`, relative to the original distance.
	 * @param precision Relative target precision of the interpolation. Defaults to 1% distance remaining.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float {
		if (deltaTime == 0)
			return base;
		if (base == target)
			return target;
		return lerp(target, base, Math.pow(precision, deltaTime / duration));
	}

	/**
	 * Linear interpolation.
	 *
	 * @param base The starting value, when `alpha = 0`.
	 * @param target The ending value, when `alpha = 1`.
	 * @param alpha The percentage of the interpolation from `base` to `target`. Forms a "line" intersecting the two.
	 *
	 * @return The interpolated value.
	 */
	public static function lerp(base:Float, target:Float, alpha:Float):Float {
		if (alpha == 0)
			return base;
		if (alpha == 1)
			return target;
		return base + alpha * (target - base);
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

package utils;

import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import core.json.objects.AlphabetData;
import core.enums.AlphabetStyle;

class Alphabet extends core.assets.FunkinSprite {
	public var char(default, null):String;
	public var style(default, null):AlphabetStyle;

	public var charWidth(get, never):Float;

	function get_charWidth():Float
		return width;

	public function new(char:String, style:AlphabetStyle, x:Float = 0, y:Float = 0) {
		super(x, y);
		this.char = char;
		this.style = style;
		loadChar(char, style);
	}

	function loadChar(char:String, style:AlphabetStyle):Void {
		frames = Paths.getPath("alphabet",'animated');

		var xmlChar = charToXmlName(char, style);
		var prefix = '$xmlChar $style instance ';

		animation.addByPrefix('idle', prefix, 24, true);

		if (animation.exists('idle')) {
			animation.play('idle');
			updateHitbox();
		} else {
			visible = false;
			Trace.traceOnce('Alphabet: "$char" style="$style" not in atlas');
		}
	}

	static function charToXmlName(char:String, style:AlphabetStyle):String {
		return char;
	}

	public static function resolveStyle(char:String, wantBold:Bool):AlphabetStyle {
		var code = char.charCodeAt(0);
		var isLetter = (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || code > 127;

		if (!isLetter)
			return wantBold ? Bold : Normal;

		if (wantBold)
			return Bold;

		return (char == char.toUpperCase()) ? Uppercase : Lowercase;
	}
}

class AlphabetGroup extends FlxSpriteGroup {
	public var text(default, set):String;
	public var style(default, null):AlphabetStyle;
	public var separation:Float;

	var _chars:Array<Alphabet> = [];

	var _isMenuItem:Bool = false;
	var _bobTweens:Array<FlxTween> = [];

	public function new(data:AlphabetData) {
		super(data.x ?? 0, data.y ?? 0);

		style = data.style ?? Bold;
		separation = data.separation ?? 0.0;
		alpha = data.alpha ?? 1.0;

		if (data.color != null)
			color = FlxColor.fromString(data.color);

		if (data.scale != null)
			scale.set(data.scale, data.scale);

		_isMenuItem = data.isMenuItem ?? false;

		setText(data.text, data.letterDelay ?? 0.0);

		if (data.centered == true)
			x -= width * 0.5;
	}

	function set_text(v:String):String {
		if (text == v)
			return v;
		text = v;
		setText(v, 0);
		return v;
	}

	function setText(str:String, letterDelay:Float):Void {
		clearChars();

		var curX:Float = 0;

		for (i in 0...str.length) {
			var c = str.charAt(i);

			if (c == ' ') {
				curX += 20 + separation;
				continue;
			}

			var resolvedStyle = Alphabet.resolveStyle(c, style == Bold);
			var letter = new Alphabet(c, resolvedStyle, curX, 0);

			if (letterDelay > 0) {
				letter.alpha = 0;
				FlxTween.tween(letter, {alpha: 1.0}, 0.2, {
					startDelay: letterDelay * i,
					ease: FlxEase.quadOut
				});
			}

			_chars.push(letter);
			add(letter);

			curX += letter.charWidth + separation;
		}

		if (_isMenuItem)
			applyBob();
	}

	function applyBob():Void {
		killBobTweens();

		for (i in 0..._chars.length) {
			var letter = _chars[i];
			var baseY = letter.y;

			var t = FlxTween.tween(letter, {y: baseY + 5}, 0.6, {
				ease: FlxEase.sineInOut,
				type: FlxTweenType.PINGPONG,
				startDelay: i * 0.05
			});

			_bobTweens.push(t);
		}
	}

	function killBobTweens():Void {
		for (t in _bobTweens)
			t.cancel();
		_bobTweens = [];
	}

	public var textWidth(get, never):Float;

	function get_textWidth():Float
		return width;

	function clearChars():Void {
		killBobTweens();
		for (c in _chars) {
			remove(c, true);
			c.destroy();
		}
		_chars = [];
	}

	override public function destroy():Void {
		killBobTweens();
		_chars = null;
		super.destroy();
	}
}

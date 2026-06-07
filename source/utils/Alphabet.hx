package utils;

import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import core.json.objects.AlphabetData;
import core.json.objects.AlphabetData.AlphabetStyle;
import core.assets.FunkinSprite;

class Alphabet extends FunkinSprite {
	public var char(default, null):String;
	public var style(default, null):AlphabetStyle;

	public var charWidth(get, never):Float;

	function get_charWidth():Float
		return width;

	public var path:String = "alphabet";

	public function new(char:String, style:AlphabetStyle, x:Float = 0, y:Float = 0)
    {
        super(x, y);
        this.char  = char;
        this.style = style;
        loadChar(char, style);
    }

	public function getChar(index:Int):String {
		if (index < 0 || index >= alphabet.length)
			return "";
		return alphabet.charAt(index);
	}

	public function loadSpriteSheet(charWidth:Int, charHeight:Int):FlxSprite {
		var sprite = new FunkinSprite();
		sprite.loadGraphic(Paths.getPath(path, 'image'), true, false, charWidth, charHeight);

		return sprite;
	}
}

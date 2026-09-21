package states.menus;

import flixel.util.FlxColor;
import core.rhythm.audio.MasterAudio;
import modding.scripting.types.ScriptClass;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import core.json.engine.CreditsData.CreditEntry;

class CreditsState extends MusicBeatState {
	#if windows
	static final CREDITS_FONT = 'Consolas';
	#elseif mac
	static final CREDITS_FONT = 'Menlo';
	#else
	static final CREDITS_FONT = 'Courier New';
	#end
	static final SCROLL_SPEED:Float = 60;

	static final HEADER_SIZE:Int = 22;
	static final BODY_SIZE:Int = 16;

	static final HEADER_COLOR:FlxColor = FlxColor.YELLOW;
	static final BODY_COLOR:FlxColor = FlxColor.WHITE;

	static final PADDING_X:Float = 0.06;
	static final GAP_AFTER_HEADER:Float = 6;
	static final GAP_AFTER_SECTION:Float = 36;

	var acceptOption:Bool = false;
	var totalHeight:Float = 0;

	var bg:flixel.FlxSprite;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		MasterAudio.playMenu(Paths.getPath('menus/freeplayRandom/freeplayRandom', 'music'), 0.6, 145);

		bg = new flixel.FlxSprite().makeGraphic(FlxG.width, 10, FlxColor.BLACK);
		bg.scrollFactor.set(1, 1);
		add(bg);

		buildCredits();

		bg.scale.y = (totalHeight + FlxG.height * 2) / 10;
		bg.updateHitbox();
		bg.y = -FlxG.height;

		camera.scroll.y = 0;
	}

	function buildCredits() {
		var creditsData:CreditEntry = FormatJson.readJson(Paths.getPath('data/credits', 'json'));
		
		var curY:Float = FlxG.height * 0.35 + GAP_AFTER_SECTION * 2;

		for (entry in creditsData.entries) {
			var header = makeText(FlxG.width * PADDING_X, curY, entry.header, HEADER_SIZE, HEADER_COLOR);
			add(header);
			curY += header.height + GAP_AFTER_HEADER;

			for (item in entry.body) {
				var line = makeText(FlxG.width * PADDING_X + 16, curY, item.line, BODY_SIZE, BODY_COLOR);
				add(line);
				curY += line.height + 4;
			}

			curY += GAP_AFTER_SECTION;
		}

		var endText = makeText(FlxG.width * PADDING_X, curY + GAP_AFTER_SECTION, 'Thanks for playing!', HEADER_SIZE, HEADER_COLOR, CENTER);
		endText.x = (FlxG.width - endText.fieldWidth) * 0.5;
		add(endText);

		curY += endText.height + GAP_AFTER_SECTION * 2;

		totalHeight = curY;
	}

	function makeText(x:Float, y:Float, text:String, size:Int, color:FlxColor, ?align:FlxTextAlign):FlxText {
		var t = new FlxText(x, y, 0, text);
		t.font = CREDITS_FONT;
		t.setFormat(CREDITS_FONT, size, color, align ?? FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, true);
		t.fieldWidth = FlxG.width * (1 - PADDING_X * 2);
		t.antialiasing = SaveData.data.antialiasing;
		t.scrollFactor.set(1, 1);
		return t;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		if (Controls.BACK) {
			exitCredits();
			return;
		}

		camera.scroll.y += SCROLL_SPEED * elapsed;

		if (camera.scroll.y >= totalHeight) {
			exitCredits();
		}
	}

	function exitCredits() {
		if (acceptOption)
			return;
		acceptOption = true;

		camera.fade(FlxColor.BLACK, 0.8, false, function() {
			ScriptClass.switchState('MainMenuState');
		});
	}
}

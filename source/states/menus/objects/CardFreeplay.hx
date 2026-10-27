package states.menus.objects;

import openfl.filters.GlowFilter;
import openfl.filters.BitmapFilterQuality;

class CardFreeplay extends flixel.group.FlxSpriteGroup {
	public var card:core.assets.FunkinSprite;
	public var black:core.assets.FunkinSprite;
	public var songText:flixel.text.FlxText;

	var songStartX:Float = 0;
	var songFullWidth:Float = 0;
	var scrollSpeed:Float = 60.0;
	var pauseTimer:Float = 0.0;
	var pauseDuration:Float = 1.5;

	var scrollDirection:Int = 1;

	var windowX:Float = 210;
	var windowW:Float = 230;

	public function new(x:Float, y:Float, ID:Int) {
		super(x, y);

		this.ID = ID;

		black = new core.assets.FunkinSprite(60, 30, true);
		black.frames = Paths.getPath('menus/freeplay/Screen', 'animated');
		black.addAnim('idle', 'idle', 24, false);
		black.addAnim('selected', 'selected', 12, true);
		black.antialiasing = SaveData.data.antialiasing;
		black.scale.set(0.95, 0.95);
		black.updateHitbox();
		black.ID = ID;
		add(black);
	}

	var scrollOffset:Float = 0.0;

	public function createCard(x:Float, y:Float, songName:String, ID:Int) {
		songText = new flixel.text.FlxText(windowX, 65, 0, songName);
		songText.setFormat(Paths.getPath('5by7.ttf', 'font'), 38, 0xFFFFFFFF);
		@:privateAccess songText.textField.filters = [
			new GlowFilter(flixel.util.FlxColor.fromString('#001b3a'), 1.0, 10, 10, 100, BitmapFilterQuality.MEDIUM)
		];
		songText.clipRect = new flixel.math.FlxRect(0, 0, windowW, 80);
		songText.antialiasing = SaveData.data.antialiasing;
		songText.ID = ID;
		add(songText);

		card = new core.assets.FunkinSprite(0, 0, true);
		card.frames = Paths.getPath('menus/freeplay/Song Select', 'animated');
		card.animation.addByPrefix('idle', 'idle', 24, false);
		card.animation.addByPrefix('selected', 'selected', 24, true);
		card.antialiasing = SaveData.data.antialiasing;
		card.scale.set(0.95, 0.95);
		card.updateHitbox();
		card.ID = ID;
		add(card);

		scrollOffset = 0.0;
		songStartX = songText.x;
		songFullWidth = songText.width;
		pauseTimer = pauseDuration;
		scrollDirection = 1;
	}

	var atEnd:Bool = false;

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (songText == null || songFullWidth <= windowW)
			return;

		if (pauseTimer > 0) {
			pauseTimer -= elapsed;
			return;
		}

		scrollOffset += scrollSpeed * elapsed * scrollDirection;

		var maxScroll = songFullWidth - windowW;

		if (scrollDirection == 1 && scrollOffset >= maxScroll) {
			scrollOffset = maxScroll;
			scrollDirection = -1;
			pauseTimer = pauseDuration;
		} else if (scrollDirection == -1 && scrollOffset <= 0) {
			scrollOffset = 0;
			scrollDirection = 1;
			pauseTimer = pauseDuration;
		}

		songText.x = songStartX - scrollOffset;
		songText.clipRect = new flixel.math.FlxRect(scrollOffset, 0, windowW, 80);
	}
}

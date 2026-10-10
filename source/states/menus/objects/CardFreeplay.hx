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
	var scrolling:Bool = false;

	var windowX:Float = 210;
	var windowW:Float = 392;

	var _clipRect:openfl.geom.Rectangle = new openfl.geom.Rectangle(0, 0, 392, 80);

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
		songStartX = windowX;
		songFullWidth = songText.width;
		pauseTimer = pauseDuration;
		scrolling = false;
		@:privateAccess songText.textField.scrollRect = _clipRect;
	}

	var atEnd:Bool = false;

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (songText == null || songFullWidth <= windowW)
			return;

		if (pauseTimer > 0) {
			pauseTimer -= elapsed;
			if (pauseTimer <= 0 && atEnd) {
				scrollOffset = 0.0;
				_clipRect.x = 0;
				@:privateAccess songText.textField.scrollRect = _clipRect;
				atEnd = false;
				pauseTimer = pauseDuration;
			}
			return;
		}

		scrollOffset += scrollSpeed * elapsed;
		_clipRect.x = scrollOffset;
		@:privateAccess songText.textField.scrollRect = _clipRect;

		var maxScroll = songFullWidth - windowW + 20;
		if (scrollOffset >= maxScroll) {
			scrollOffset = maxScroll;
			_clipRect.x = scrollOffset;
			@:privateAccess songText.textField.scrollRect = _clipRect;
			atEnd = true;
			pauseTimer = pauseDuration;
		}
	}
}

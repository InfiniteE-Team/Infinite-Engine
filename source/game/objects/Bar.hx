package game.objects;

import flixel.math.FlxRect;
import flixel.util.FlxColor;
import core.enums.AssignementsBar;
import core.assets.FunkinSprite;

class Bar extends flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup<FunkinSprite> {
	public var isSpriteSheet:Bool = false;
	public var spriteSheetPath:String = '';
	public var assignment:AssignementsBar = 'LEFT_TO_RIGHT';
	public var numberBars:Int = 1;

	public var minArgument:Float = 0.0;
	public var maxArgument:Float = 2.0;
	public var argument:Float = 1.0;

	var bars:Array<FunkinSprite> = [];

	// variables utils
	var barMaxWidth:Float = 0;
	var barHeight:Float = 0;

	public function new(x:Float, y:Float, argument:Float, ?assignment:AssignementsBar = 'LEFT_TO_RIGHT', ?numberBars:Int = 1, ?isSpriteSheet:Bool = false,
			?spriteSheetPath:String = '') {
		super(x, y);
		this.numberBars = numberBars;
		this.isSpriteSheet = isSpriteSheet;
		this.spriteSheetPath = spriteSheetPath;
		this.assignment = assignment;
		this.argument = argument;

		minArgument = 0;
		maxArgument = argument * 2;

		loadSpriteSheet();
	}

	public function loadSpriteSheet() {
		bars = [];
		clear();

		for (i in 0...numberBars) {
			var bar:FunkinSprite = new FunkinSprite(0, 0, true);
			if (isSpriteSheet)
				bar.loadGraphic(Paths.getPath(spriteSheetPath, 'image'));
			else
				bar.makeGraphic(592, 11, FlxColor.WHITE);
			bar.ID = i;
			/*
				if (numberBars > 1)
					bar.x += i * (bar.width + 4); */
			barMaxWidth = bar.width;
			barHeight = bar.height;
			bars.push(bar);
			add(bar);
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (argument < minArgument)
			argument = minArgument;
		if (argument > maxArgument)
			argument = maxArgument;

		var range:Float = maxArgument - minArgument;
		var percent:Float = (range <= 0) ? 0 : (argument - minArgument) / range;

		switch (assignment) {
			case 'LEFT_TO_RIGHT':
				if (numberBars == 1 && bars.length >= 1) {
					var width:Float = barMaxWidth * percent;
					if (bars[0].clipRect == null)
						bars[0].clipRect = new FlxRect(0, 0, width, barHeight);
					else {
						bars[0].clipRect.set(0, 0, width, barHeight);
						bars[0].clipRect = bars[0].clipRect;
					}
				} else if (numberBars == 2 && bars.length >= 2) {
					var totalWidth:Float = barMaxWidth;
					var width0:Float = totalWidth * (1 - percent);
					var width1:Float = totalWidth * percent;

					if (bars[0].clipRect == null)
						bars[0].clipRect = new FlxRect(0, 0, width0, barHeight);
					else
						bars[0].clipRect.set(0, 0, width0, barHeight);

					if (bars[1].clipRect == null)
						bars[1].clipRect = new FlxRect(0, 0, width1, barHeight);
					else
						bars[1].clipRect.set(0, 0, width1, barHeight);

					bars[0].clipRect = bars[0].clipRect;
					bars[1].clipRect = bars[1].clipRect;

					bars[0].x = bars[0].x; // CPU
					bars[1].x = bars[0].x + width0; // PLAYER
				}
			case 'RIGHT_TO_LEFT':
				// wip
				if (numberBars == 1 && bars.length >= 1) {
					var width:Float = barMaxWidth * percent;
					if (bars[0].clipRect == null)
						bars[0].clipRect = new FlxRect(barMaxWidth - width, 0, width, barHeight);
					else {
						bars[0].clipRect.set(barMaxWidth - width, 0, width, barHeight);
						bars[0].clipRect = bars[0].clipRect;
					}
				} else if (numberBars == 2 && bars.length >= 2) {
					var totalWidth:Float = barMaxWidth;
					var width0:Float = totalWidth * (1 - percent);
					var width1:Float = totalWidth * percent;

					if (bars[0].clipRect == null)
						bars[0].clipRect = new FlxRect(0, 0, width0, barHeight);
					else
						bars[0].clipRect.set(0, 0, width0, barHeight);

					if (bars[1].clipRect == null)
						bars[1].clipRect = new FlxRect(0, 0, width1, barHeight);
					else
						bars[1].clipRect.set(0, 0, width1, barHeight);

					bars[0].clipRect = bars[0].clipRect;
					bars[1].clipRect = bars[1].clipRect;

					bars[1].x = bars[1].x; // CPU
					bars[0].x = bars[0].x + width1; // PLAYER
				}
		}
	}

	// utils
	public function createFilledBar(barsColor:Array<FlxColor>) {
		if (isSpriteSheet)
			return;

		for (bar in bars) {
			if (barsColor.length > bar.ID) {
				bar.color = barsColor[bar.ID];
			}
		}
	}

	override function destroy() {
		bars = null;

		super.destroy();
	}
}

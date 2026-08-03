package core.ui;

import openfl.system.System;
import openfl.text.TextFieldAutoSize;
// filters
import openfl.filters.GlowFilter;
import flixel.util.FlxColor;
import openfl.filters.BitmapFilterQuality;

class FPS extends openfl.display.FPS {
	public var peakRAM:Float = 0;
	public var glowColor:FlxColor = FlxColor.fromString('#00ccff');

	public function new(x:Float, y:Float, color:Int) {
		super(x, y, color);
		autoSize = TextFieldAutoSize.LEFT;
		defaultTextFormat = new openfl.text.TextFormat(Paths.getPath("5by7_b.ttf", "font"), 14, color);
		var glow = new openfl.filters.GlowFilter(glowColor, 1.0, 6, 6, 100, BitmapFilterQuality.MEDIUM);
		filters = [glow];
	}

	@:noCompletion
	override private function __enterFrame(e:Float):Void {
		super.__enterFrame(e);
		infoFPS();
	}

	var mods:String = '';

	public function infoFPS() {
		var currentMem:Float = System.totalMemory;
		if (currentMem > peakRAM) {
			peakRAM = currentMem;
		}

		var mem:String = formatRam(currentMem);
		var maxMem:String = formatRam(peakRAM);

		if (!core.ConfigMain.globalData.developerMode) {
			text = 'FPS: $currentFPS - [MEM: $mem MB / Peak: $maxMem MB]';
		} else {
			if (modding.mods.ModsRegistry.onMod)
				mods = ' - ' + modding.mods.ModsRegistry.currentMod;

			text = 'FPS: $currentFPS - [MEM: $mem / $maxMem]\n\nDeveloper Mode' + mods;
		}
	}

	public function formatRam(r:Float):String {
		var mb = r / (1024 * 1024);
		if (mb >= 1024) {
			var gb = mb / 1024;
			return (Math.round(gb * 100) / 100) + ' GB';
		}
		return (Math.round(mb * 100) / 100) + ' MB';
	}
}

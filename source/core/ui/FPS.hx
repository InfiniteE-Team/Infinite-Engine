package core.ui;

import core.api.Memory;
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
		var currentMem:Float = Memory.getProcessMemoryMB();
		if (currentMem > peakRAM) {
			peakRAM = currentMem;
		}

		var mem:String = Memory.formatRam(currentMem);
		var maxMem:String = Memory.formatRam(peakRAM);

		if (!core.ConfigMain.globalData.developerMode) {
			text = 'FPS: $currentFPS - [MEM: $mem / Peak: $maxMem]';
		} else {
			if (modding.mods.ModsRegistry.onMod)
				mods = ' - ' + modding.mods.ModsRegistry.currentMod;

			text = 'FPS: $currentFPS - [MEM: $mem / $maxMem] - (Developer Mode' + mods + ')';
		}
	}
}

package core.system;

import cpp.vm.Gc;
import openfl.system.System;
import openfl.text.TextFieldAutoSize;
// filters
import openfl.filters.GlowFilter;
import flixel.util.FlxColor;
import openfl.filters.BitmapFilterQuality;

class FPS extends openfl.display.FPS {
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

	public function infoFPS() {
		var mem:Float = formatRam(System.totalMemory);

		if (!core.ConfigMain.globalData.developerMode) {
			var memGC:Float = formatRam(Gc.memUsage());
			text = 'FPS: $currentFPS - [MEM: $mem MB / GC: $memGC MB]';
		} else {
			var memGC:Float = formatRam(Gc.memUsage());
			text = 'FPS: $currentFPS - [MEM: $mem MB / GC: $memGC MB]\n\nDeveloper Mode';
		}
	}

	public function formatRam(r:Float):Float {
		var ram = Math.round(r / 1024 / 1024 * 100) / 100;
		return ram;
	}
}

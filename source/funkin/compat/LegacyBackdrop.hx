package funkin.compat;

import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;

// shortcut: V-Slice mods still call FlxBackdrop(graphic, scrollX, scrollY, repeatX, repeatY) from flixel-addons 2, mapped onto 4.x -JloorDev
@:keep
class LegacyBackdrop extends FlxBackdrop {
	public var zIndex:Int = 0;

	public function new(?graphic:flixel.system.FlxAssets.FlxGraphicAsset, scrollX:Float = 1, scrollY:Float = 1, repeatX:Bool = true, repeatY:Bool = true) {
		super(graphic, repeatX && repeatY ? XY : (repeatX ? X : (repeatY ? Y : NONE)));
		scrollFactor.set(scrollX, scrollY);
	}
}

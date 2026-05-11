package core.system;
#if cpp
import cpp.vm.Gc;
#end
import openfl.system.System;
import openfl.text.TextFieldAutoSize;

class FPS extends openfl.display.FPS
{
    public function new(x:Float, y:Float, color:Int) {
		super(x,y,color);
		autoSize = TextFieldAutoSize.LEFT;
    }
    
    @:noCompletion
	override private function __enterFrame(e:Float):Void {
		super.__enterFrame(e);
		infoFPS();
	}

    public function infoFPS() {
		var mem:Float = formatRam(System.totalMemory);
		#if cpp
		var memGC:Float = formatRam(Gc.memUsage());
		text = 'FPS: $currentFPS - [MEM: $mem MB / GC: $memGC MB]';
		#else
		text = 'FPS: $currentFPS - [MEM: $mem MB]';
		#end
    }

	public function formatRam(r:Float):Float{
		var ram = Math.round(r / 1024 / 1024 * 100) / 100;
		return ram;
	}
}
package states;

import cpp.vm.Gc;

class State extends flixel.FlxState {
	public function new() {
		super();
	}

	override function destroy() {
		super.destroy();
		#if cpp
		Gc.run(true);
		Gc.compact();
		#end
	}
}

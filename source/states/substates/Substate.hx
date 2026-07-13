package states.substates;

import cpp.vm.Gc;

class Substate extends flixel.FlxSubState {
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



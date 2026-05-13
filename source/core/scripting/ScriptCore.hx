package core.scripting;

import flixel.FlxState;
import rulescript.RuleScript;

class ScriptCore {
	var script:RuleScript = new RuleScript();

	public function new(state:Class<FlxState>) {
		refClass(state);
	}

	public function refClass(state:Class<FlxState>) {
		for (field in Type.getInstanceFields(Type.getClass(state)) script.set(field, Reflect.field(state, field)));
		script.set("add", state.add);
		script.set("remove", state.remove);
	}

	public function call(name:String, args:Array<Dynamic>) {
		var func = script.get(name);
		if (func != null)
			Reflect.callMethod(script, func, args);
	}

	public function reload() {}
}
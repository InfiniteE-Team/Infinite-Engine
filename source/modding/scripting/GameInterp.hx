package modding.scripting;

import hxscript.runtime.Interp;

@:access(hxscript.runtime.Interp)
class GameInterp extends Interp {
	public var context:Dynamic = null;

	var instanceFields:Map<String, Bool> = new Map();
	var staticFields:Map<String, Bool> = new Map();

	static var fieldCache:Map<String, Map<String, Bool>> = new Map();

	public function new(?env, ?parent) {
		super(env, parent);
	}

	public function setContext(value:Dynamic):Void {
		context = value;
		if (value == null) {
			instanceFields = new Map();
			staticFields = new Map();
			return;
		}

		var className = Type.getClassName(Type.getClass(value));

		if (fieldCache.exists('i:$className') && fieldCache.exists('s:$className')) {
			instanceFields = fieldCache.get('i:$className');
			staticFields = fieldCache.get('s:$className');
			return;
		}

		instanceFields = new Map();
		staticFields = new Map();

		var cls = Type.getClass(value);
		while (cls != null) {
			for (fallback in Type.getInstanceFields(cls))
				instanceFields.set(fallback, true);
			for (fallback in Type.getClassFields(cls))
				staticFields.set(fallback, true);
			cls = Type.getSuperClass(cls);
		}

		fieldCache.set('i:$className', instanceFields);
		fieldCache.set('s:$className', staticFields);
	}

	override public function isResolvable(id:String):Bool {
		return super.isResolvable(id) || (context != null && (instanceFields.exists(id) || staticFields.exists(id)));
	}

	override public function resolve(id:String):Dynamic {
		if (variables.exists(id))
			return variables.get(id);

		if (context != null) {
			if (staticFields.exists(id))
				return Reflect.getProperty(Type.getClass(context), id);
			if (instanceFields.exists(id))
				return Reflect.getProperty(context, id);
		}

		return super.resolve(id);
	}

	override function setVar(name:String, value:Dynamic):Dynamic {
		if (!variables.exists(name) && context != null) {
			if (staticFields.exists(name)) {
				Reflect.setProperty(Type.getClass(context), name, value);
				return value;
			}
			if (instanceFields.exists(name)) {
				Reflect.setProperty(context, name, value);
				return value;
			}
		}
		return super.setVar(name, value);
	}
}

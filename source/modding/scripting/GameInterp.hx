package modding.scripting;

import hxscript.runtime.Interp;
import hxscript.syntax.Expr;
import hxscript.syntax.ExprTools;

@:access(hxscript.runtime.Interp)
class GameInterp extends Interp {
	public var context:Dynamic = null;

	var instanceFields:Map<String, Bool> = new Map();
	var staticFields:Map<String, Bool> = new Map();

	static var fieldCache:Map<String, Map<String, Bool>> = new Map();

	static var functionFieldCache:Map<String, Bool> = new Map();

	var _resolving:Map<String, Bool> = new Map();

	public function new(?env, ?parent) {
		super(env, parent);
	}

	public function setContext(value:Dynamic):Void {
		context = value;
		_resolving.clear();

		if (value == null) {
			instanceFields = new Map();
			staticFields = new Map();
			return;
		}

		var className = Type.getClassName(Type.getClass(value));
		var iKey = 'i:$className';
		var sKey = 's:$className';

		if (fieldCache.exists(iKey) && fieldCache.exists(sKey)) {
			instanceFields = fieldCache.get(iKey);
			staticFields = fieldCache.get(sKey);
			return;
		}

		instanceFields = new Map();
		staticFields = new Map();

		var cls = Type.getClass(value);
		while (cls != null) {
			for (f in Type.getInstanceFields(cls))
				instanceFields.set(f, true);
			for (f in Type.getClassFields(cls))
				staticFields.set(f, true);
			cls = Type.getSuperClass(cls);
		}

		fieldCache.set(iKey, instanceFields);
		fieldCache.set(sKey, staticFields);
	}

	override public function isResolvable(id:String):Bool {
		return super.isResolvable(id) || (context != null && (instanceFields.exists(id) || staticFields.exists(id)));
	}

	override public function resolve(id:String):Dynamic {
		if (variables.exists(id))
			return variables.get(id);
		if (context != null) {
			if (_resolving.exists(id))
				return null;

			if (staticFields.exists(id)) {
				_resolving.set(id, true);
				var v = Reflect.getProperty(Type.getClass(context), id);
				_resolving.remove(id);
				if (Reflect.isFunction(v))
					variables.set(id, v);
				return v;
			}

			if (instanceFields.exists(id)) {
				_resolving.set(id, true);
				var v = Reflect.getProperty(context, id);
				_resolving.remove(id);
				if (Reflect.isFunction(v))
					variables.set(id, v);
				return v;
			}
		}

		if (environment != null && environment.variables.exists(id)) {
			var v = environment.variables.get(id);
			variables.set(id, v);
			return v;
		}

		return super.resolve(id);
	}

	override function assign(e1:Expr, e2:Expr):Dynamic {
		switch (ExprTools.expr(e1)) {
			case EField(e, f, true): // null-safe ?.
				var obj = expr(e);
				if (obj == null)
					return null;
				var v = expr(e2);
				return set(obj, f, v);
			default:
				return super.assign(e1, e2);
		}
	}

	override function evalAssignOp(op:String, e1:Expr, e2:Expr):Dynamic {
		switch (ExprTools.expr(e1)) {
			case EField(e, f, true):
				var obj = expr(e);
				if (obj == null)
					return null;
				var v = combine(op, get(obj, f), expr(e2), e1, e2);
				return set(obj, f, v);
			default:
				return super.evalAssignOp(op, e1, e2);
		}
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

package modding.scripting.lua;

import hxluajit.Lua;
import hxluajit.LuaL;
import hxluajit.LuaJIT;
import hxluajit.Types;
import sys.FileSystem;

class LuaScript {
	var L:cpp.RawPointer<Lua_State>;
	var superInstance:Dynamic;
	var path:String;

	public static var globalClasses:Map<String, Dynamic> = null;

	static var _stateMap:Map<Int, LuaScript> = [];

	static inline function stateKey(L:cpp.RawPointer<Lua_State>):Int {
		return untyped __cpp__("(int)(intptr_t)({0})", L);
	}

	var _callbacks:Map<String, Dynamic> = [];
	var _requireCache:Map<String, Dynamic> = [];

	var ownedObjectIds:Array<Int> = [];

	static var _globalCallbacks:Map<String, Dynamic> = [];
	static var _dispatchFn:Lua_CFunction = cpp.Callable.fromStaticFunction(_dispatch);

	static function _dispatch(L:cpp.RawPointer<Lua_State>):Int {
		var fname:String = Lua.tostring(L, Lua.upvalueindex(1));
		var self = _stateMap.get(stateKey(L));
		if (self == null || fname == null)
			return 0;
		var fn = self._callbacks.get(fname);
		if (fn == null)
			return 0;
		var args = self.readArgs(L);
		var ret:Dynamic = Reflect.callMethod(null, fn, args);
		if (ret != null) {
			self.pushValue(ret);
			return 1;
		}
		return 0;
	}

	static var _hxIndexFn:Lua_CFunction = cpp.Callable.fromStaticFunction(_hxIndexCallback);

	public function new(path:String, superInstance:Dynamic) {
		this.path = path;
		this.superInstance = superInstance;

		L = LuaL.newstate();
		LuaL.openlibs(L);
		LuaJIT.setmode(L, 0, LuaJIT.MODE_ENGINE | LuaJIT.MODE_ON);

		_stateMap.set(stateKey(L), this);

		ScriptGlobals.initLua();
		registerCoreFunctions();
		registerClasses();
		registersuperInstance();

		var err = LuaL.dofile(L, path);
		if (err != 0)
			traceError('dofile');
	}

	public function call(func:String, ?args:Array<Dynamic>):Dynamic {
		Lua.getglobal(L, func);
		if (Lua.isnil(L, -1) != 0) {
			Lua.pop(L, 1);
			return null;
		}
		var argc = 0;
		if (args != null) {
			for (a in args)
				pushValue(a);
			argc = args.length;
		}
		if (Lua.pcall(L, argc, 1, 0) != 0) {
			traceError(func);
			Lua.pop(L, 1);
			return null;
		}
		var result = readValue(L, -1);
		Lua.pop(L, 1);
		return result;
	}

	public function callCancellable(func:String, ?args:Array<Dynamic>):Bool {
		var result:Dynamic = call(func, args);
		var isTrue:Bool = result == true;
		var isOne:Bool = result == 1;
		return isTrue || isOne;
	}

	public function expose(name:String, value:Dynamic):Void {
		pushValue(value);
		Lua.setglobal(L, name);
	}

	function registerClasses():Void {
		if (globalClasses == null)
			return;
		for (name => cls in globalClasses) {
			pushHaxeClass(cls);
			Lua.setglobal(L, name);
		}
	}

	public function registersuperInstance():Void {
		for (field in Reflect.fields(superInstance)) {
			try {
				var val = Reflect.field(superInstance, field);
				pushValue(val);
				Lua.setglobal(L, field);
			} catch (e:Dynamic) {
				Console.log('[LuaScript] registersuperInstance: skip field "$field": $e', true);
			}
		}
		var cls = Type.getClass(superInstance);
		if (cls != null) {
			for (field in Type.getInstanceFields(cls)) {
				try {
					var val = Reflect.getProperty(superInstance, field);
					if (val == null || Reflect.isFunction(val))
						continue;
					pushValue(val);
					Lua.setglobal(L, field);
				} catch (e:Dynamic) {
					Console.log('[LuaScript] registersuperInstance: skip property "$field": $e', true);
				}
			}
		}
	}

	function luaFunction(name:String, fn:Dynamic):Void {
		_callbacks.set(name, fn);
		Lua.pushstring(L, name);
		Lua.pushcclosure(L, _dispatchFn, 1);
		Lua.setglobal(L, name);
	}

	function luaFunctionAt(tableIdx:Int, name:String, fn:Dynamic):Void {
		var key = '__tbl_${name}_${metaCounter++}';
		_callbacks.set(key, fn);
		Lua.pushstring(L, key);
		Lua.pushcclosure(L, _dispatchFn, 1);
		Lua.setfield(L, tableIdx, name);
	}

	function luaFunctionAtDynamic(tableIdx:Int, name:String, fn:Array<Dynamic>->Dynamic):Void {
		luaFunctionAt(tableIdx, name, function() {
			return null;
		});
		var key = '__tbl_${name}_${metaCounter}';
		_callbacks.set(key, fn);
	}

	function registerCoreFunctions():Void {
		luaFunction("require", function(name:String):Dynamic {
			if (_requireCache.exists(name))
				return _requireCache[name];

			if (globalClasses != null && globalClasses.exists(name)) {
				var cls = globalClasses[name];
				_requireCache.set(name, cls);
				return cls;
			}

			var cls = Type.resolveClass(name);
			if (cls != null) {
				_requireCache.set(name, cls);
				return cls;
			}

			var enm = Type.resolveEnum(name);
			if (enm != null) {
				_requireCache.set(name, enm);
				return enm;
			}

			var luaName = name.split('.').join('/') + '.lua';
			var candidates = [
				haxe.io.Path.directory(path) + '/' + luaName,
				core.assets.Library.findLib('scripts/$luaName'),
				core.assets.Library.findLib(luaName),
			];
			for (candidate in candidates) {
				if (candidate != null && sys.FileSystem.exists(candidate)) {
					var top = Lua.gettop(L);
					var err = LuaL.dofile(L, candidate);
					if (err != 0) {
						traceError('require($name)');
						Lua.pop(L, 1);
						return null;
					}
					var newTop = Lua.gettop(L);
					var result:Dynamic = null;
					if (newTop > top) {
						result = readValue(L, -1);
						Lua.pop(L, newTop - top);
					}
					_requireCache.set(name, result ?? true);
					return result;
				}
			}

			Console.log('[LuaScript] require("$name"): not found', true);
			return null;
		});

		luaFunction("import", function(classPath:String, varName:String):Dynamic {
			var cls = Type.resolveClass(classPath) ?? cast Type.resolveEnum(classPath);
			if (cls == null && globalClasses != null)
				cls = globalClasses.get(classPath);
			if (cls != null) {
				pushHaxeClass(cls);
				Lua.setglobal(L, varName);
			} else {
				Console.log('[LuaScript] import("$classPath", "$varName"): not found', true);
			}
			return null;
		});

		luaFunction("print", function(args:Dynamic):Dynamic {
			trace('[Lua:$path] $args');
			return null;
		});

		luaFunction("getProperty", function(p:String):Dynamic {
			return resolvePath(superInstance, p);
		});

		luaFunction("setProperty", function(p:String, val:Dynamic):Dynamic {
			setPath(superInstance, p, val);
			return null;
		});

		luaFunction("callMethod", function(p:String, args:Dynamic):Dynamic {
			var parts = p.split('.');
			var methodName = parts.pop();
			var obj = parts.length > 0 ? resolvePath(superInstance, parts.join('.')) : superInstance;
			if (obj == null)
				return null;
			var fn = Reflect.field(obj, methodName);
			if (fn == null || !Reflect.isFunction(fn))
				return null;
			return Reflect.callMethod(obj, fn, args);
		});

		luaFunction("addHaxeLibrary", function(varName:String, classPath:String):Dynamic {
			var full = classPath != null && classPath.length > 0 ? '$classPath.$varName' : varName;
			var cls = Type.resolveClass(full);
			if (cls != null) {
				pushHaxeClass(cls);
				Lua.setglobal(L, varName);
			}
			return null;
		});

		luaFunction("luaCallback", function(funcName:String):Dynamic {
			final self = this;
			return Reflect.makeVarArgs(function(callArgs:Array<Dynamic>):Dynamic {
				Lua.getglobal(self.L, funcName);
				var argc = 0;
				if (callArgs != null) {
					for (a in callArgs) {
						self.pushValue(a);
						argc++;
					}
				}
				if (Lua.pcall(self.L, argc, 0, 0) != 0) {
					self.traceError(funcName);
					Lua.pop(self.L, 1);
				}
				return null;
			});
		});

		LuaL.dostring(L, "
			function class(base)
				local cls = {}
				cls.__index = cls
				if base then
					setmetatable(cls, { __index = base })
				end
				setmetatable(cls, {
					__index = base,
					__call = function(c, ...)
						local instance = setmetatable({}, c)
						if base and base.new then
							instance.super = function(...)
								base.new(instance, ...)
							end
						else
							instance.super = function() end
						end
						if c.new then
							c.new(instance, ...)
						end
						return instance
					end
				})
				cls.isInstanceOf = function(self, klass)
					local mt = getmetatable(self)
					while mt do
						if mt == klass then return true end
						local parent = getmetatable(mt)
						mt = parent and parent.__index
					end
					return false
				end
				return cls
			end
		");
	}

	// metatables

	function pushHaxeInstance(obj:Dynamic):Void {
		if (obj == null) {
			Lua.pushnil(L);
			return;
		}

		var id = registerObject(obj);
		Lua.newtable(L);
		var tableIdx = Lua.gettop(L);
		Lua.pushinteger(L, id);
		Lua.setfield(L, tableIdx, "__hx_id");

		Lua.newtable(L);
		var metaIdx = Lua.gettop(L);

		// __index
		Lua.pushstring(L, "__index");
		Lua.pushcclosure(L, _hxIndexFn, 0);
		Lua.settable(L, metaIdx);

		// __newindex
		var capturedId = id;
		luaFunctionAt(metaIdx, "__newindex", function(tbl:Dynamic, key:String, val:Dynamic):Dynamic {
			var o = getObject(capturedId);
			if (o != null)
				Reflect.setProperty(o, key, val);
			return null;
		});

		// __tostring
		luaFunctionAt(metaIdx, "__tostring", function(tbl:Dynamic):Dynamic {
			var o = getObject(capturedId);
			return o != null ? Std.string(o) : "null";
		});

		Lua.setmetatable(L, tableIdx);
	}

	function pushHaxeClass(cls:Class<Dynamic>):Void {
		if (cls == null) {
			Lua.pushnil(L);
			return;
		}
		Lua.newtable(L);
		var tableIdx = Lua.gettop(L);

		for (field in Type.getClassFields(cls)) {
			var val = Reflect.field(cls, field);
			if (val == null)
				continue;
			if (Reflect.isFunction(val)) {
				var captured = val;
				var capturedCls = cls;
				var key = '__static_${Type.getClassName(cls)}_${field}';
				_callbacks.set(key, function():Dynamic {
					var args = readArgs(L);
					return Reflect.callMethod(capturedCls, captured, args);
				});
				Lua.pushstring(L, key);
				Lua.pushcclosure(L, _dispatchFn, 1);
				Lua.setfield(L, tableIdx, field);
			} else {
				Lua.pushstring(L, field);
				pushValue(val);
				Lua.settable(L, tableIdx);
			}
		}

		var capturedCls = cls;
		Lua.newtable(L);
		var metaIdx = Lua.gettop(L);
		luaFunctionAt(metaIdx, "__call", function(args:Array<Dynamic>):Dynamic {
			if (args.length > 0)
				args.shift();
			return Type.createInstance(capturedCls, args);
		});
		Lua.setmetatable(L, tableIdx);
	}

	static function _hxIndexCallback(L:cpp.RawPointer<Lua_State>):Int {
		var self = _stateMap.get(stateKey(L));
		if (self == null) {
			Lua.pushnil(L);
			return 1;
		}
		var key:String = Lua.tostring(L, 2);
		Lua.getfield(L, 1, "__hx_id");
		var oid:Int = (Lua.tointeger(L, -1) : Int);
		Lua.pop(L, 1);
		var o = getObject(oid);
		if (o == null) {
			Lua.pushnil(L);
			return 1;
		}

		var val = Reflect.getProperty(o, key);
		if (val == null)
			val = Reflect.field(o, key);

		if (val != null && Reflect.isFunction(val)) {
			var methodKey = '__method_${oid}_${key}';
			if (!self._callbacks.exists(methodKey)) {
				self._callbacks.set(methodKey, function():Dynamic {
					var freshO = getObject(oid);
					var freshFn = Reflect.getProperty(freshO, key);
					if (freshFn == null)
						freshFn = Reflect.field(freshO, key);
					var args = self.readArgs(L);
					return Reflect.callMethod(freshO, freshFn, args);
				});
			}
			Lua.pushstring(L, methodKey);
			Lua.pushcclosure(L, _dispatchFn, 1);
		} else {
			self.pushValue(val);
		}
		return 1;
	}

	function pushHaxeFunction(fn:Dynamic):Void {
		var key = '__hxfn_${metaCounter++}';
		_callbacks.set(key, function():Dynamic {
			var args = readArgs(L);
			return Reflect.callMethod(null, fn, args);
		});
		Lua.pushstring(L, key);
		Lua.pushcclosure(L, _dispatchFn, 1);
	}

	static var objectPool:Array<Dynamic> = [];
	static var poolFreeIds:Array<Int> = [];

	function registerObject(obj:Dynamic):Int {
		var id:Int;
		if (poolFreeIds.length > 0) {
			id = poolFreeIds.pop();
			objectPool[id] = obj;
		} else {
			objectPool.push(obj);
			id = objectPool.length - 1;
		}
		ownedObjectIds.push(id);
		return id;
	}

	static function getObject(id:Int):Dynamic {
		if (id < 0 || id >= objectPool.length)
			return null;
		return objectPool[id];
	}

	function pushValue(v:Dynamic):Void {
		if (v == null)
			Lua.pushnil(L);
		else if (Std.isOfType(v, Bool))
			Lua.pushboolean(L, v ? 1 : 0);
		else if (Std.isOfType(v, Int))
			Lua.pushinteger(L, (v : Int));
		else if (Std.isOfType(v, Float))
			Lua.pushnumber(L, v);
		else if (Std.isOfType(v, String))
			Lua.pushstring(L, (v : String));
		else if (Reflect.isFunction(v))
			pushHaxeFunction(v);
		else if (Std.isOfType(v, Array)) {
			var arr:Array<Dynamic> = v;
			Lua.newtable(L);
			for (i in 0...arr.length) {
				pushValue(arr[i]);
				Lua.rawseti(L, -2, i + 1);
			}
		} else
			pushHaxeInstance(v);
	}

	function readValue(L:cpp.RawPointer<Lua_State>, idx:Int):Dynamic {
		var t = Lua.type(L, idx);
		return switch (t) {
			case _ if (t == Lua.TNIL): null;
			case _ if (t == Lua.TBOOLEAN): Lua.toboolean(L, idx) != 0;
			case _ if (t == Lua.TNUMBER):
				var n:Float = Lua.tonumber(L, idx);
				var i = Std.int(n);
				(i == n) ? i : n;
			case _ if (t == Lua.TSTRING): (Lua.tostring(L, idx) : String);
			case _ if (t == Lua.TTABLE):
				Lua.getfield(L, idx, "__hx_id");
				if (Lua.isnil(L, -1) == 0) {
					var id = Lua.tointeger(L, -1);
					Lua.pop(L, 1);
					getObject(id);
				} else {
					Lua.pop(L, 1);
					var map:Map<String, Dynamic> = [];
					Lua.pushnil(L);
					while (Lua.next(L, idx) != 0) {
						var key:String = Lua.tostring(L, -2);
						var val = readValue(L, -1);
						map.set(key, val);
						Lua.pop(L, 1);
					}
					map;
				}
			case _ if (t == Lua.TFUNCTION):
				var fnName = '__hxluafn_${metaCounter++}';
				Lua.pushvalue(L, idx);
				Lua.setglobal(L, fnName);
				final self = this;
				Reflect.makeVarArgs(function(callArgs:Array<Dynamic>):Dynamic {
					Lua.getglobal(self.L, fnName);
					var argc = 0;
					if (callArgs != null) {
						for (a in callArgs) {
							self.pushValue(a);
							argc++;
						}
					}
					if (Lua.pcall(self.L, argc, 1, 0) != 0) {
						self.traceError(fnName);
						Lua.pop(self.L, 1);
						return null;
					}
					var ret = self.readValue(self.L, -1);
					Lua.pop(self.L, 1);
					return ret;
				});
			default: null;
		}
	}

	function readArgs(L:cpp.RawPointer<Lua_State>, startIdx:Int = 1):Array<Dynamic> {
		var n = Lua.gettop(L);
		var args:Array<Dynamic> = [];
		for (i in startIdx...(n + 1))
			args.push(readValue(L, i));
		return args;
	}

	static function resolvePath(root:Dynamic, path:String):Dynamic {
		var parts = path.split('.');
		var cur:Dynamic = root;
		for (p in parts) {
			if (cur == null)
				return null;
			var next = Reflect.getProperty(cur, p);
			if (next == null)
				next = Reflect.field(cur, p);
			cur = next;
		}
		return cur;
	}

	static function setPath(root:Dynamic, path:String, value:Dynamic):Void {
		var parts = path.split('.');
		var last = parts.pop();
		var cur:Dynamic = parts.length > 0 ? resolvePath(root, parts.join('.')) : root;
		if (cur != null)
			Reflect.setProperty(cur, last, value);
	}

	function traceError(context:String):Void {
		var rawMsg:cpp.ConstCharStar = Lua.tostring(L, -1);
		var msg:String = rawMsg != null ? (rawMsg : String) : '(null)';

		Lua.getglobal(L, "debug");
		if (Lua.istable(L, -1) != 0) {
			Lua.getfield(L, -1, "traceback");
			if (Lua.isfunction(L, -1) != 0) {
				var msgForLua:cpp.ConstCharStar = (msg : cpp.ConstCharStar);
				Lua.pushstring(L, msgForLua);
				Lua.pushinteger(L, 2);
				if (Lua.pcall(L, 2, 1, 0) == 0) {
					var tb:cpp.ConstCharStar = Lua.tostring(L, -1);
					if (tb != null)
						msg = (tb : String);
					Lua.pop(L, 1);
				} else {
					Lua.pop(L, 1);
				}
			} else {
				Lua.pop(L, 1);
			}
		}
		Lua.pop(L, 1);

		Console.log('[LuaScript] $path → $context:\n$msg', true);
	}

	static var metaCounter:Int = 0;

	public function destroy():Void {
		if (L != null) {
			_stateMap.remove(stateKey(L));
			Lua.close(L);
			L = null;
		}
		if (ownedObjectIds != null) {
			for (id in ownedObjectIds) {
				if (id >= 0 && id < objectPool.length) {
					objectPool[id] = null;
					poolFreeIds.push(id);
				}
			}
			ownedObjectIds = null;
		}
		_callbacks = null;
		_requireCache = null;
		superInstance = null;
	}
}

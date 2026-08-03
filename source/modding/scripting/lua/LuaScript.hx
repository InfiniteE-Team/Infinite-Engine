package modding.scripting.lua;

import llua.*;
import llua.Lua.Lua_helper;
import sys.FileSystem;

class LuaScript {
	var L:State;
	var superInstance:Dynamic;
	var path:String;

	public static var globalClasses:Map<String, Dynamic> = null;

	static var _current:LuaScript = null;

	static var _stateMap:Map<String, LuaScript> = [];

	static inline function stateKey(L:State):String {
		return Std.string(L);
	}

	public function new(path:String, superInstance:Dynamic) {
		this.path = path;
		this.superInstance = superInstance;
		L = LuaL.newstate();
		LuaL.openlibs(L);
		Lua.init_callbacks(L);
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(_callbackHandler));
		ScriptGlobals.initLua();
		registerCoreFunctions();
		registerClasses();
		registersuperInstance();
		_stateMap.set(stateKey(L), this);
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
		var result = call(func, args);
		return result == true;
	}

	public function expose(name:String, value:Dynamic):Void {
		pushValue(value);
		Lua.setglobal(L, name);
	}

	function registerClasses():Void {
		for (name => cls in globalClasses) {
			pushHaxeClass(cls);
			Lua.setglobal(L, name);
		}
	}

	public function registersuperInstance():Void {
		// superInstance RuleScript but in Lua
		for (field in Reflect.fields(superInstance)) {
			var val = Reflect.field(superInstance, field);
			pushValue(val);
			Lua.setglobal(L, field);
		}
		var cls = Type.getClass(superInstance);
		if (cls != null) {
			for (field in Type.getInstanceFields(cls)) {
				var val = Reflect.getProperty(superInstance, field);
				if (val != null) {
					pushValue(val);
					Lua.setglobal(L, field);
				}
			}
		}
	}

	var _requireCache:Map<String, Dynamic> = [];

	function registerCoreFunctions():Void {
		_current = this;

		// require: require("FlxTween") or require("flixel.tweens.FlxTween")
		luaFunction("require", function(name:String):Dynamic {
			if (_requireCache.exists(name))
				return _requireCache[name];

			// Class registred globalClasses (name, ex: "FlxTween")
			if (globalClasses != null && globalClasses.exists(name)) {
				var cls = globalClasses[name];
				_requireCache.set(name, cls);
				return cls;
			}

			// Class Haxe name complete (ex: "flixel.tweens.FlxTween")
			var cls = Type.resolveClass(name);
			if (cls != null) {
				_requireCache.set(name, cls);
				return cls;
			}

			// Enum Haxe (ex: "flixel.util.FlxAxes")
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

			Trace.traceOnce('[LuaScript] require("$name"): not found', true);
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
			// filter nulls to final
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
			var wrapper:Dynamic = function(arg:Dynamic) {
				Lua.getglobal(L, funcName);
				Convert.toLua(L, arg);
				Lua.pcall(L, 1, 0, 0);
			};
			return wrapper; // dynamic not good converter fuck
		});

		LuaL.dostring(L, "
			function class(base)
				local cls = {}
				cls.__index = cls

				if base then
					setmetatable(cls, { __index = base })
				end

    			-- perms for: local obj = MyClass(args)
				setmetatable(cls, {
					__index = base,
					__call = function(c, ...)
						local instance = setmetatable({}, c)
						-- exposes super as a function that calls new() from the parent
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

		luaFunctionAt(metaIdx, "__index", _hxIndexCallback);

		// capt the id in clousure, not stack
		var capturedId = id;
		luaFunctionAt(metaIdx, "__newindex", function(tbl:Dynamic, key:String, val:Dynamic):Dynamic {
			var o = getObject(capturedId); // id captured
			if (o != null)
				Reflect.setProperty(o, key, val);
			return null;
		});

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

		// statics metodes
		for (field in Type.getClassFields(cls)) {
			var val = Reflect.field(cls, field);
			if (val == null)
				continue;
			if (Reflect.isFunction(val)) {
				var captured = val;
				var capturedCls = cls;
				luaFunctionAtDynamic(tableIdx, field, function(args:Array<Dynamic>):Dynamic {
					return Reflect.callMethod(capturedCls, captured, args);
				});
			} else {
				Lua.pushstring(L, field);
				pushValue(val);
				Lua.settable(L, tableIdx);
			}
		}

		var capturedCls = cls;
		Lua.newtable(L);
		luaFunctionAtDynamic(Lua.gettop(L), "__call", function(args:Array<Dynamic>):Dynamic {
			if (args.length > 0)
				args.shift();
			return Type.createInstance(capturedCls, args);
		});
		Lua.setmetatable(L, tableIdx);
	}

	static function _hxIndexCallback(L:State):Int {
		var self = _stateMap.get(stateKey(L));
		if (self == null) {
			Lua.pushnil(L);
			return 1;
		}
		var key = Lua.tostring(L, 2);
		Lua.getfield(L, 1, "__hx_id");
		var oid = Lua.tointeger(L, -1);
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
			var methodName = '__method_${_metaCounter++}';
			var capturedO = o;
			var capturedFn = val;
			var wrapper = function(L:State, _:String):Int {
				var args = self.readArgs(L);
				var ret = Reflect.callMethod(capturedO, capturedFn, args);
				if (ret != null) {
					self.pushValue(ret);
					return 1;
				}
				return 0;
			};
			Lua_helper.add_callback(L, methodName, wrapper);
			Lua.getglobal(L, methodName);
			// not clean the global
		} else {
			self.pushValue(val);
		}
		return 1;
	}

	function luaFunctionAtDynamic(tableIdx:Int, name:String, fn:Array<Dynamic>->Dynamic):Void {
		var uniqueName = '__meta_${name}_${_metaCounter++}';
		var self = this;
		var wrapper = function(L:State, _:String):Int {
			var args = self.readArgs(L);
			var ret = fn(args);
			if (ret != null) {
				self.pushValue(ret);
				return 1;
			}
			return 0;
		};
		Lua_helper.add_callback(L, uniqueName, wrapper);
		Lua.getglobal(L, uniqueName);
		Lua.setfield(L, tableIdx, name);
		Lua.pushnil(L);
		Lua.setglobal(L, uniqueName);
	}

	function pushHaxeFunction(fn:Dynamic):Void {
		var uniqueName = '__hxfn_${_metaCounter++}';
		var self = this;
		var wrapper = function(L:State, _:String):Int {
			var args = self.readArgs(L);
			var ret:Dynamic = Reflect.callMethod(null, fn, args);
			if (ret != null) {
				self.pushValue(ret);
				return 1;
			}
			return 0;
		};
		Lua_helper.add_callback(L, uniqueName, wrapper);
		Lua.getglobal(L, uniqueName);
		Lua.pushnil(L);
		Lua.setglobal(L, uniqueName);
	}

	static var objectPool:Array<Dynamic> = [];
	static var poolFreeIds:Array<Int> = [];

	static function registerObject(obj:Dynamic):Int {
		if (poolFreeIds.length > 0) {
			var id = poolFreeIds.pop();
			objectPool[id] = obj;
			return id;
		}
		objectPool.push(obj);
		return objectPool.length - 1;
	}

	static function getObject(id:Int):Dynamic {
		if (id < 0 || id >= objectPool.length)
			return null;
		return objectPool[id];
	}

	function pushValue(v:Dynamic):Void {
		if (v == null) {
			Lua.pushnil(L);
		} else if (Std.isOfType(v, Bool)) {
			Lua.pushboolean(L, v);
		} else if (Std.isOfType(v, Int)) {
			Lua.pushinteger(L, v);
		} else if (Std.isOfType(v, Float)) {
			Lua.pushnumber(L, v);
		} else if (Std.isOfType(v, String)) {
			Lua.pushstring(L, v);
		} else if (Reflect.isFunction(v)) {
			pushHaxeFunction(v);
		} else if (Std.isOfType(v, Array)) {
			// array Haxe
			var arr:Array<Dynamic> = v;
			Lua.newtable(L);
			for (i in 0...arr.length) {
				pushValue(arr[i]);
				Lua.rawseti(L, -2, i + 1);
			}
		} else {
			// Haxe Obj -> instance
			pushHaxeInstance(v);
		}
	}

	function readValue(L:State, idx:Int):Dynamic {
		var t = Lua.type(L, idx);
		return switch (t) {
			case Lua.LUA_TNIL: null;
			case Lua.LUA_TBOOLEAN: Lua.toboolean(L, idx);
			case Lua.LUA_TNUMBER:
				var n = Lua.tonumber(L, idx);
				var i = Std.int(n);
				(i == n) ? i : n;
			case Lua.LUA_TSTRING: Lua.tostring(L, idx);
			case Lua.LUA_TTABLE:
				// try recupere the Haxe obj for __hx_id
				Lua.getfield(L, idx, "__hx_id");
				if (Lua.isnil(L, -1) == 0) {
					var id = Lua.tointeger(L, -1);
					Lua.pop(L, 1);
					getObject(id);
				} else {
					Lua.pop(L, 1);
					// table plane → Map<String, Dynamic>
					var map:Map<String, Dynamic> = [];
					Lua.pushnil(L);
					while (Lua.next(L, idx) != 0) {
						var key = Lua.tostring(L, -2);
						var val = readValue(L, -1);
						map.set(key, val);
						Lua.pop(L, 1);
					}
					map;
				}
			case Lua.LUA_TFUNCTION:
				final fnName = '__hxluafn_${_metaCounter++}';
				Lua.pushvalue(L, idx);
				Lua.setglobal(L, fnName);
				final self = this;
				(function():Dynamic {
					Lua.getglobal(self.L, fnName);
					if (Lua.pcall(self.L, 0, 1, 0) != 0) {
						self.traceError(fnName);
						Lua.pop(self.L, 1);
						return null;
					}
					var ret = self.readValue(self.L, -1);
					Lua.pop(self.L, 1);
					return ret;
				});
			case _: null;
		}
	}

	// helpers

	static function _callbackHandler(L:State, fname:String):Int {
		var cbf = Lua_helper.callbacks.get(fname);
		if (cbf == null)
			return 0;

		var args:Array<Dynamic> = [];
		for (i in 0...Lua.gettop(L))
			args[i] = Convert.fromLua(L, i + 1);

		var ret:Dynamic = Reflect.callMethod(null, cbf, args);

		if (ret != null) {
			var self = _stateMap.get(stateKey(L));
			if (self != null)
				self.pushValue(ret);
			else
				Convert.toLua(L, ret);
			return 1;
		}
		return 0;
	}

	function readArgs(L:State, startIdx:Int = 1):Array<Dynamic> {
		var n = Lua.gettop(L);
		var args:Array<Dynamic> = [];
		for (i in startIdx...(n + 1))
			args.push(readValue(L, i));
		return args;
	}

	// resolvePath(superInstance, "noteController.scrollSpeed") → value
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

	// setPath(superInstance, "noteController.scrollSpeed", 2.5)
	static function setPath(root:Dynamic, path:String, value:Dynamic):Void {
		var parts = path.split('.');
		var last = parts.pop();
		var cur:Dynamic = parts.length > 0 ? resolvePath(root, parts.join('.')) : root;
		if (cur != null)
			Reflect.setProperty(cur, last, value);
	}

	function luaFunction(name:String, fn:Dynamic):Void {
		Lua_helper.add_callback(L, name, fn);
	}

	static var _metaCounter:Int = 0;

	// Function register for stack
	function luaFunctionAt(tableIdx:Int, name:String, fn:Dynamic):Void {
		var uniqueName = '__meta_${name}_${_metaCounter++}'; // ← counter global
		Lua_helper.add_callback(L, uniqueName, fn);
		Lua.getglobal(L, uniqueName);
		Lua.setfield(L, tableIdx, name);
		// clear
		Lua.pushnil(L);
		Lua.setglobal(L, uniqueName);
	}

	/*
		// Push function anonime to stack (for __index dynamic)
		function luaFunctionInline(fn:State->Int):Void {
			Lua.pushcfunction(L, cpp.Callable.fromStaticFunction(fn));
	}*/
	function traceError(context:String):Void {
		var msg = Lua.tostring(L, -1);
		Trace.traceOnce('[LuaScript] $path → $context: $msg', true);
	}

	public function destroy():Void {
		if (L != null) {
			Lua.close(L);
			_stateMap.remove(stateKey(L));
			L = null;
		}
		_requireCache = null;
		superInstance = null;
	}
}

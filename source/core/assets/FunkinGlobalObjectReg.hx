package core.assets;

class FunkinGlobalObjectReg {
    static var _registry:Map<String, Dynamic> = new Map();

    public static function set(name:String, obj:Dynamic):Void {
        _registry.set(name, obj);
    }

    public static function get(name:String):Dynamic {
        return _registry.get(name);
    }

    public static function remove(name:String):Void {
        _registry.remove(name);
    }

    public static function exists(name:String):Bool {
        return _registry.exists(name);
    }

    public static function clear():Void {
        _registry.clear();
    }
}
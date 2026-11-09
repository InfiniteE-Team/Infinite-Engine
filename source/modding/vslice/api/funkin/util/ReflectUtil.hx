package funkin.util;

@:keep
class ReflectUtil {
	public static function getClassNameOf(obj:Dynamic):String {
		var cls = Type.getClass(obj);
		return cls != null ? Type.getClassName(cls) : null;
	}

	public static function getClassFields(cls:Class<Dynamic>):Array<String>
		return Type.getClassFields(cls);

	public static function getInstanceFields(cls:Class<Dynamic>):Array<String>
		return Type.getInstanceFields(cls);

	public static function getAnonymousField(obj:Dynamic, name:String):Dynamic
		return Reflect.field(obj, name);

	public static function setAnonymousField(obj:Dynamic, name:String, value:Dynamic):Void
		Reflect.setField(obj, name, value);

	public static function hasAnonymousField(obj:Dynamic, name:String):Bool
		return Reflect.hasField(obj, name);
}

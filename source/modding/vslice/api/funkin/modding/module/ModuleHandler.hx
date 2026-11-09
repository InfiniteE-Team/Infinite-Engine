package funkin.modding.module;

@:keep
class ModuleHandler {
	public static var modules:Array<Module> = [];

	public static function getModule(id:String):Null<Module> {
		for (m in modules)
			if (m.moduleId == id)
				return m;
		return null;
	}
}

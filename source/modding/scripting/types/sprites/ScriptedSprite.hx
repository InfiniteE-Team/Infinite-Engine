package modding.scripting.types.sprites;

#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

class ScriptedSprite extends core.assets.FunkinSprite {
	#if HSCRIPT_ALLOWED
	public var script:ScriptHandler;
	#end

	var scriptPath:String = '';

	#if HSCRIPT_ALLOWED
	public function initScript(path:String):Void {
		scriptPath = path;
		script = new ScriptHandler(this);
		script.load(Paths.getPath(path, 'script'));
		script.executeAll();
		script.call('postCreate', []);
	}
	#end

	override public function destroy():Void {
		#if HSCRIPT_ALLOWED
		if (script != null) {
			script.call('onDestroy', []);
			script.destroy();
			script = null;
		}
		#end
		super.destroy();
	}
}

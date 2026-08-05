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
	public function initScript(scriptPath:String):Void {
		this.scriptPath = scriptPath;
		script = new ScriptHandler(this);
		script.load(Paths.getPath(scriptPath, 'script'));
		script.executeAll();
	}
	#end

	override public function destroy() {
        #if HSCRIPT_ALLOWED
		script.call('onDestroy', []);
		script.destroy();
		script = null;
		#end
    }
}

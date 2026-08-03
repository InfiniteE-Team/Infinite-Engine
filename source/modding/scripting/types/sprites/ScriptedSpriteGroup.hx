package modding.scripting.types.sprites;

#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

class ScriptedSpriteGroup extends core.assets.FunkinObjectRegistry {
	#if HSCRIPT_ALLOWED
	public var script:ScriptHandler;
	#end

	var scriptPath:String = '';

	#if HSCRIPT_ALLOWED
	public function initScript(scriptPath:String):Void {
		scriptPath = this.scriptPath;
		script = new ScriptHandler(this);
		script.load(Paths.getPath(scriptPath, 'script'));
		script.executeAll();
	}
	#end

	override public function update(elapsed:Float) {
		super.update(elapsed);
		#if HSCRIPT_ALLOWED
		script.call('onUpdate', [elapsed]);
		#end
	}

    override public function destroy() {
        #if HSCRIPT_ALLOWED
		script.call('onDestroy', []);
		script.destroy();
		script = null;
		#end
    }
}

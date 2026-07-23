package states.substates;

class OptionsMenuSubstate extends MusicBeatSubstate {
	var options:Array<String> = [];

	override public function create() {
		super.create();

		#if HSCRIPT_ALLOWED
		initScript();
		script.executeAll();
		script.call("onCreate", []);
		#end

		#if HSCRIPT_ALLOWED
		script.call("postCreate", []);
		#end
	}

	override public function update(elapsed:Float) {
		#if HSCRIPT_ALLOWED
		script.call("onUpdate", [elapsed]);
		#end

        if (Controls.BACK)
            close();

		super.update(elapsed);

		#if HSCRIPT_ALLOWED
		script.call("postUpdate", [elapsed]);
		#end
	}

	override function destroy() {
		super.destroy();
	}
}

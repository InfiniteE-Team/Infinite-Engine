package game.controllers.events;

import core.json.song.SongData.SongConfig;
import game.PlayState;
import core.json.song.SongData.EventsData;
import game.objects.sprites.Character;
#if HSCRIPT_ALLOWED
import core.scripting.ScriptHandler;
#end

class EventManager {
	#if HSCRIPT_ALLOWED
	public var eventScript:ScriptHandler;
	#end
	public var pendingEvents:Array<EventsData> = [];
	public var onEvent:(EventsData) -> Void = null;

	public function new() {}

	#if HSCRIPT_ALLOWED
	public function initEventScript(events:Array<EventsData>):Void {
		eventScript = new ScriptHandler(this);
		var loadedScripts:Array<String> = [];
		for (event in events) {
			if (loadedScripts.contains(event.name))
				continue;
			eventScript.load(Paths.getPath('events/' + event.name, 'script'));
			loadedScripts.push(event.name);
		}
		eventScript.executeAll();
		eventScript.call('onCreate', []);
	}
	#end

	public function loadEvents(events:Array<EventsData>) {
		pendingEvents = events.copy();
		pendingEvents.sort((a, b) -> Std.int(a.time - b.time));

		onEvent = handleEvent;

		#if HSCRIPT_ALLOWED
		initEventScript(events);
		#end
	}

	function handleEvent(event:EventsData) {
		switch (event.name) {
			case 'Camera Follow':
				PlayState.instance.cameraController.existsCamEvents = true;
				var charId:String = Reflect.field(event.arguments, 'char');
				var char = PlayState.instance.chars.get(charId);
				if (char == null) {
					Trace.traceOnce('Camera Follow char "$charId" not found');
					return;
				}
				PlayState.instance.cameraController.char = cast(char, Character);
			case 'Change Scroll Speed':
				var newSpeed:Float = Std.parseFloat(event.arguments[0]);

				if (!Math.isNaN(newSpeed)) {
					PlayState.instance.noteController.targetScrollSpeed = newSpeed;
				}
		}

		#if HSCRIPT_ALLOWED
		eventScript.call('onEvent', [event.name, event.arguments, event.time]);
		#end
	}

	public function updateEvents(songTime:Float) {
		while (pendingEvents.length > 0 && pendingEvents[0].time <= songTime) {
			var event = pendingEvents.shift();
			if (onEvent != null)
				onEvent(event);
		}
	}

	public function destroy() {
		pendingEvents = null;
		onEvent = null;
	}
}

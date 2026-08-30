package game.controllers.events;

import core.json.song.SongData.SongConfig;
import game.PlayState;
import core.json.song.SongData.EventsData;
import game.objects.sprites.Character;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

class EventManager {
	#if HSCRIPT_ALLOWED
	var eventScripts:Map<String, ScriptHandler> = [];
	#end

	public var pendingEvents:Array<EventsData> = [];
	public var onEvent:(EventsData) -> Void = null;

	public function new() {}

	#if HSCRIPT_ALLOWED
	public function initEventScripts(events:Array<EventsData>):Void {
		var loadedScripts:Array<String> = [];
		for (event in events) {
			if (loadedScripts.contains(event.name))
				continue;
			var path = Paths.getPath('events/' + event.name, 'script');
			if (path == null || !sys.FileSystem.exists(path)) {
				loadedScripts.push(event.name);
				continue;
			}
			var handler = new ScriptHandler(this);
			handler.load(path);
			handler.executeAll();
			handler.call('onCreate', []);
			eventScripts.set(event.name, handler);

			loadedScripts.push(event.name);
		}
	}
	#end

	public function loadEvents(events:Array<EventsData>) {
		pendingEvents = events.copy();
		pendingEvents.sort((a, b) -> Std.int(a.time - b.time));

		onEvent = handleEvent;

		#if HSCRIPT_ALLOWED
		initEventScripts(events);
		#end
	}

	public function triggerEvent(name:String, arguments:Dynamic, ?time:Float = 0):Void {
		var event:EventsData = {name: name, arguments: arguments, time: time};
		if (onEvent != null)
			onEvent(event);
	}

	function handleEvent(event:EventsData) {
		switch (event.name) {
			case 'Camera Follow':
				PlayState.instance.cameraController.existsCamEvents = true;
				var charId:String = Reflect.field(event.arguments, 'char');
				var char = PlayState.instance.chars.get(charId);
				if (char == null) {
					Trace.traceOnce('[EventManager] Camera Follow char "$charId" not found');
					return;
				}
				PlayState.instance.cameraController.char = cast(char, Character);
			case 'Change Scroll Speed':
				var newSpeed:Float = Std.parseFloat(event.arguments[0]);
				if (!Math.isNaN(newSpeed)) {
					PlayState.instance.noteController.targetScrollSpeed = newSpeed;
				}
			case 'Play Special Anim':
				var charId:String = Reflect.field(event.arguments, 'char');
				var animKey:String = Reflect.field(event.arguments, 'anim');
				if (charId == null || animKey == null) {
					Trace.traceOnce('[EventManager] Play Special Anim: "char" or "anim" are missing from the arguments');
					return;
				}
				var success = PlayState.instance.chars.playSpecialAnim(charId, animKey);
				if (!success)
					Trace.traceOnce('[EventManager] Play Special Anim: could not be reproduced "$animKey" in "$charId"');
		}
		#if HSCRIPT_ALLOWED
		var handler = eventScripts.get(event.name);
		if (handler != null)
			handler.call('onEvent', [event.arguments, event.time]);
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
		#if HSCRIPT_ALLOWED
		for (handler in eventScripts)
			handler.destroy();
		eventScripts = null;
		#end
	}
}

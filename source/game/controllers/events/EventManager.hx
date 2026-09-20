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
			case 'Change Character':
				var charId:String = event.arguments.char;
				var newCharacter:String = event.arguments.newCharacter;
				if (charId == null || newCharacter == null) {
					Trace.traceOnce('[EventManager] Change Character: "char" or "newCharacter" are missing from the arguments.');
					return;
				}
				var char = cast PlayState.instance.chars.get(charId);
				if (char == null) {
					Trace.traceOnce('[EventManager] Change Character: char "$charId" not found');
					return;
				}
				char.changeCharacter(newCharacter);
			case 'Camera Follow':
				var charId:String = event.arguments.char;
				var char = cast PlayState.instance.chars.get(charId);
				if (char == null) {
					Trace.traceOnce('[EventManager] Camera Follow char "$charId" not found');
					return;
				}
				PlayState.instance.cameraController.existsCamEvents = true;
				PlayState.instance.cameraController.char = char;
			case 'Center Camera':
				var charId1:String = event.arguments.char1;
				var charId2:String = event.arguments.char2;
				var isLock:Bool = event.arguments.isLock;
				var char1 = cast PlayState.instance.chars.get(charId1);
				var char2 = cast PlayState.instance.chars.get(charId2);
				if (char1 == null)
					Trace.traceOnce('[EventManager] Camera Follow char "$charId1" not found');
				if (char2 == null)
					Trace.traceOnce('[EventManager] Camera Follow char "$charId2" not found');
				if (char1 == null || char2 == null)
					return;
				if (PlayState.instance.cameraController.existsCamEvents != true)
					PlayState.instance.cameraController.existsCamEvents = true;
				PlayState.instance.cameraController.centerCamera(char1, char2, isLock);
			case 'Change Scroll Speed':
				var rawSpeed = event.arguments.speed != null ? event.arguments.speed : event.arguments[0];
				var newSpeed:Float = Std.parseFloat(Std.string(rawSpeed));
				if (!Math.isNaN(newSpeed)) {
					PlayState.instance.noteController.targetScrollSpeed = newSpeed;
				}
			case 'Change BPM':
				var newBPM:Float = event.arguments.bpm;
				if (!Math.isNaN(newBPM) && newBPM > 0) {
					core.rhythm.RhythmCore.changeBPM(newBPM);
				}
			case 'Play Special Anim':
				var charId = event.arguments.char;
				var animKey = event.arguments.anim;
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

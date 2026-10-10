package game.controllers.events;

import core.json.song.SongData.SongConfig;
import game.PlayState;
import core.json.song.SongData.EventsData;
import game.objects.sprites.Character;
#if HSCRIPT_ALLOWED
import modding.scripting.ScriptHandler;
#end

typedef EventField = {
	var key:String;
	var kind:String;
	var ?step:Float;
	var ?min:Float;
	var ?max:Float;
	var ?def:Dynamic;
}

typedef EventSchema = {
	var name:String;
	var fields:Array<EventField>;
}

class EventManager {
	public static final schemas:Array<EventSchema> = [
		{name: 'Camera Follow', fields: [{key: 'char', kind: 'char'}]},
		{
			name: 'Center Camera',
			fields: [
				{key: 'char1', kind: 'char'},
				{key: 'char2', kind: 'char'},
				{key: 'isLock', kind: 'bool', def: false}
			]
		},
		{name: 'Change Character', fields: [{key: 'char', kind: 'char'}, {key: 'newCharacter', kind: 'charName'}]},
		{name: 'Change Scroll Speed', fields: [{key: 'speed', kind: 'float', step: 0.1, min: 0.5, max: 6, def: 1.5}]},
		{name: 'Change BPM', fields: [{key: 'bpm', kind: 'float', step: 1, min: 20, max: 400, def: 120}]},
		{name: 'Play Special Anim', fields: [{key: 'char', kind: 'char'}, {key: 'anim', kind: 'text', def: 'hey'}]}
	];

	public static function schemaNames():Array<String> {
		return [for (t in schemas) t.name];
	}

	public static function findSchema(name:String):EventSchema {
		for (t in schemas) {
			if (t.name == name)
				return t;
		}
		return null;
	}

	public static function defaultArgs(schema:EventSchema, chars:Array<String>, bpm:Float):Dynamic {
		var args:Dynamic = {};
		if (schema == null)
			return args;

		for (f in schema.fields) {
			var value:Dynamic = f.def;
			if (value == null) {
				switch (f.kind) {
					case 'char':
						value = chars.length > 0 ? chars[0] : '';
					case 'charName':
						value = 'bf';
					case 'float':
						value = 0.0;
					case 'bool':
						value = false;
					default:
						value = '';
				}
			}
			if (f.key == 'bpm')
				value = bpm;
			Reflect.setField(args, f.key, value);
		}
		return args;
	}

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
					Console.log('[EventManager] Change Character: "char" or "newCharacter" are missing from the arguments.');
					return;
				}
				var char = cast PlayState.instance.chars.get(charId);
				if (char == null) {
					Console.log('[EventManager] Change Character: char "$charId" not found');
					return;
				}
				char.changeCharacter(newCharacter);
			case 'Camera Follow':
				var charId:String = event.arguments.char;
				var char = cast PlayState.instance.chars.get(charId);
				if (char == null) {
					Console.log('[EventManager] Camera Follow char "$charId" not found');
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
					Console.log('[EventManager] Camera Follow char "$charId1" not found');
				if (char2 == null)
					Console.log('[EventManager] Camera Follow char "$charId2" not found');
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
					Console.log('[EventManager] Play Special Anim: "char" or "anim" are missing from the arguments');
					return;
				}
				var success = PlayState.instance.chars.playSpecialAnim(charId, animKey);
				if (!success)
					Console.log('[EventManager] Play Special Anim: could not be reproduced "$animKey" in "$charId"');
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
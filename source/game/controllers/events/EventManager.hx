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
		{
			name: 'Camera Follow',
			fields: [
				{key: 'char', kind: 'char'},
				{key: 'x', kind: 'float', step: 10, min: -5000, max: 5000, def: 0},
				{key: 'y', kind: 'float', step: 10, min: -5000, max: 5000, def: 0},
				{key: 'duration', kind: 'float', step: 1, min: 0, max: 256, def: 4},
				{key: 'ease', kind: 'text', def: 'CLASSIC'}
			]
		},
		{
			name: 'Center Camera',
			fields: [
				{key: 'char1', kind: 'char'},
				{key: 'char2', kind: 'char'},
				{key: 'isLock', kind: 'bool', def: false}
			]
		},
		{name: 'Change Character', fields: [{key: 'char', kind: 'char'}, {key: 'newCharacter', kind: 'charName'}]},
		{
			name: 'Change Scroll Speed',
			fields: [
				{key: 'speed', kind: 'float', step: 0.1, min: 0.5, max: 6, def: 1.5},
				{key: 'duration', kind: 'float', step: 1, min: 0, max: 256, def: 0},
				{key: 'ease', kind: 'text', def: 'linear'}
			]
		},
		{name: 'Change BPM', fields: [{key: 'bpm', kind: 'float', step: 1, min: 20, max: 400, def: 120}]},
		{name: 'Play Special Anim', fields: [{key: 'char', kind: 'char'}, {key: 'anim', kind: 'text', def: 'hey'}]},
		{
			name: 'Zoom Camera',
			fields: [
				{key: 'zoom', kind: 'float', step: 0.05, min: 0.1, max: 5, def: 1},
				{key: 'duration', kind: 'float', step: 1, min: 0, max: 256, def: 4},
				{key: 'ease', kind: 'text', def: 'expoOut'},
				{key: 'mode', kind: 'text', def: 'stage'}
			]
		},
		{name: 'Change Note Skin', fields: [{key: 'char', kind: 'char'}, {key: 'skin', kind: 'text', def: 'default'}]},
		{
			name: 'Play Video',
			fields: [{key: 'video', kind: 'text', def: ''}, {key: 'camera', kind: 'text', def: 'other'}]
		},
		{
			name: 'Camera Bop',
			fields: [
				{key: 'rate', kind: 'float', step: 1, min: 0, max: 16, def: 4},
				{key: 'intensity', kind: 'float', step: 0.1, min: 0, max: 5, def: 1}
			]
		}
	];

	public static function easeByName(name:String):Null<flixel.tweens.FlxEase.EaseFunction> {
		if (name == null)
			return flixel.tweens.FlxEase.linear;
		var f = Reflect.field(flixel.tweens.FlxEase, name);
		return Reflect.isFunction(f) ? f : null;
	}

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
	public var videos:SongVideos = new SongVideos();
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
		videos.preload(events);

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
				if (char.curCharacter != newCharacter) {
					char.changeCharacter(newCharacter);
					PlayState.instance.applyStageProps(char, charId);
				}
			case 'Camera Follow':
				var charId:String = event.arguments.char;
				var char:Character = charId != null && charId != '' ? cast PlayState.instance.chars.get(charId) : null;
				if (charId != null && charId != '' && char == null) {
					Console.log('[EventManager] Camera Follow char "$charId" not found');
					return;
				}
				var easeName:String = event.arguments.ease ?? 'CLASSIC';
				var steps:Float = event.arguments.duration ?? 4.0;
				PlayState.instance.cameraController.existsCamEvents = true;
				PlayState.instance.cameraController.focusOn(char, event.arguments.x ?? 0.0, event.arguments.y ?? 0.0,
					steps * core.rhythm.RhythmCore.stepInMs / 1000, easeName == 'CLASSIC' ? null : easeByName(easeName), easeName == 'INSTANT');
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
					if (event.arguments.duration == null)
						PlayState.instance.noteController.targetScrollSpeed = newSpeed;
					else {
						var steps:Float = event.arguments.duration;
						PlayState.instance.noteController.tweenScrollSpeed(newSpeed, steps * core.rhythm.RhythmCore.stepInMs / 1000, easeByName(event.arguments.ease));
					}
				}
			case 'Change BPM':
				var newBPM:Float = event.arguments.bpm;
				if (!Math.isNaN(newBPM) && newBPM > 0) {
					core.rhythm.RhythmCore.changeBPM(newBPM);
					PlayState.instance?.rhythmTracker?.onBpmChange();
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
			case 'Zoom Camera':
				var cam = PlayState.instance.cameraController;
				var zoom:Float = event.arguments.zoom ?? 1.0;
				if (event.arguments.mode != 'direct')
					zoom *= cam.stageZoom;
				var steps:Float = event.arguments.duration ?? 4.0;
				cam.zoomTo(zoom, steps * core.rhythm.RhythmCore.stepInMs / 1000, easeByName(event.arguments.ease));
			case 'Change Note Skin':
				var charId:String = event.arguments.char;
				var skin:String = event.arguments.skin;
				if (!PlayState.instance.noteController.changeCharSkin(charId, skin))
					Console.log('[EventManager] Change Note Skin: char "$charId" or skin "$skin" not found');
			case 'Play Video':
				var name:String = event.arguments.video;
				if (name == null || name == '' || !videos.play(name, event.arguments.camera ?? 'other'))
					Console.log('[EventManager] Play Video: could not play "$name"');
			case 'Camera Bop':
				var cam = PlayState.instance.cameraController;
				cam.bopEvery = Std.int(event.arguments.rate ?? 4);
				cam.bopIntensity = event.arguments.intensity ?? 1.0;
		}
		modding.vslice.VSliceHooks.songEvent(event);
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
		videos.destroy();
		pendingEvents = null;
		onEvent = null;
		#if HSCRIPT_ALLOWED
		for (handler in eventScripts)
			handler.destroy();
		eventScripts = null;
		#end
	}
}
package modding.editors.gameplay;

import game.controllers.CameraController;
import game.controllers.CharacterController;
import game.controllers.events.EventManager;
import game.objects.Camera;
import game.objects.sprites.Character;
import core.json.song.SongData.EventsData;

class PreviewEvents {
	public var follow:Bool = true;

	var cam:Camera;
	var camCtrl:CameraController;
	var chars:CharacterController;
	var charData:Array<core.json.song.SongData.CharDataJson> = [];
	var onCharChanged:Character->Void;

	var events:Array<EventsData> = [];
	var index:Int = 0;

	var currentNames:Map<String, String> = new Map();
	var speed:Float = 1;
	var bpm:Float = 120;
	var lastEvent:String = '';
	var lastEventChar:String = '-';

	public var lastError:String = '';

	public function new(onCharChanged:Character->Void) {
		this.onCharChanged = onCharChanged;
	}

	public function attach(cam:Camera, chars:CharacterController, charData:Array<core.json.song.SongData.CharDataJson>, speed:Float, bpm:Float):Void {
		this.cam = cam;
		this.chars = chars;
		this.charData = charData ?? [];
		this.speed = speed;
		this.bpm = bpm;

		var currentZoom:Float = cam != null ? cam.zoom : 1.0;
		camCtrl = new CameraController(cam, null);
		camCtrl.zoomEnabled = false;
		camCtrl.lerp = 0.04;
		camCtrl.defaultZoom = currentZoom;
		camCtrl.stageZoom = currentZoom;

		currentNames = new Map();
		for (c in this.charData)
			currentNames.set(c.id, c.name);
	}

	function charOf(id:String):Character {
		if (chars == null || id == null)
			return null;
		return cast(chars.get(id), Character);
	}

	function opponentId():String {
		for (c in charData) {
			if (CharacterController.namesOpponent.contains(c.role))
				return c.id;
		}
		return charData.length > 0 ? charData[0].id : null;
	}

	public function reset(list:Array<EventsData>, pos:Float):Void {
		if (chars == null)
			return;

		if (camCtrl != null)
			camCtrl.cancelTweens();

		events = (list ?? []).copy();
		events.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
		index = 0;

		// pick the final char first, before it loaded each sheet twice per scroll -JloorDev
		var wanted:Map<String, String> = new Map();
		for (c in charData)
			wanted.set(c.id, c.name);
		var last:Int = 0;
		while (last < events.length && events[last].time <= pos) {
			var e = events[last++];
			var id:String = arg(e, 'char');
			var name:String = arg(e, 'newCharacter');
			if (e.name == 'Change Character' && id != null && name != null && wanted.exists(id))
				wanted.set(id, name);
		}
		for (id => name in wanted)
			setCharacter(id, name, 'restore');

		lastEvent = '';
		lastEventChar = '-';

		if (camCtrl != null) {
			var initChar = charOf(opponentId());
			camCtrl.char = initChar;
			if (initChar != null) {
				var p = initChar.getCamPosition();
				camCtrl.snapCameraTo(p.x, p.y);
			}
		}

		while (index < last) {
			if (events[index].name != 'Change Character')
				fire(events[index], true);
			else
				lastEvent = events[index].name;
			index++;
		}
	}

	public function advance(pos:Float):Void {
		while (index < events.length && events[index].time <= pos) {
			fire(events[index], false);
			index++;
		}
	}

	function stepsToSeconds(steps:Float):Float {
		return steps * (60.0 / bpm) / 4.0;
	}

	public function noteSung(char:Character):Void {
		if (camCtrl != null && !camCtrl.existsCamEvents && char != null)
			camCtrl.char = char;
	}

	function setCharacter(id:String, name:String, why:String):Void {
		var char = charOf(id);
		if (char == null || name == null)
			return;

		currentNames.set(id, name);
		if (char.curCharacter == name)
			return;

		try {
			char.changeCharacter(name);
			onCharChanged(char);
		} catch (e:Dynamic) {
			lastError = '$why $id: $e';
			Console.log('PreviewEvents: could not put "$name" on "$id" ($why): $e', true);
		}
	}

	function arg(e:EventsData, key:String):Dynamic {
		return e.arguments == null ? null : Reflect.field(e.arguments, key);
	}

	function fire(e:EventsData, silent:Bool):Void {
		lastEvent = e.name;
		if (camCtrl == null)
			return;
		try {
			switch (e.name) {
				case 'Change Character':
					var id:String = arg(e, 'char');
					var name:String = arg(e, 'newCharacter');
					if (name != null)
						setCharacter(id, name, 'event');

				case 'Camera Follow':
					var char = charOf(arg(e, 'char'));
					var ox:Float = arg(e, 'x') ?? 0;
					var oy:Float = arg(e, 'y') ?? 0;
					var steps:Float = arg(e, 'duration') ?? 4.0;
					var easeName:String = arg(e, 'ease') ?? 'CLASSIC';
					var isClassic = easeName == 'CLASSIC';
					var isInstant = easeName == 'INSTANT';
					var snap = silent || (isInstant && steps <= 0);
					var ease = (isClassic || isInstant) ? null : EventManager.easeByName(easeName);
					var duration = (isClassic || isInstant || snap) ? 0.0 : stepsToSeconds(steps);
					camCtrl.existsCamEvents = true;
					lastEventChar = arg(e, 'char') ?? '-';
					camCtrl.focusOn(char, ox, oy, duration, ease, snap);

				case 'Center Camera':
					var a = charOf(arg(e, 'char1'));
					var b = charOf(arg(e, 'char2'));
					if (a != null && b != null) {
						camCtrl.existsCamEvents = true;
						camCtrl.centerCamera(a, b, arg(e, 'isLock') == true);
					}

				case 'Zoom Camera':
					var zoom:Float = arg(e, 'zoom') ?? 1.0;
					var mode:String = arg(e, 'mode') ?? 'stage';
					if (mode != 'direct')
						zoom *= camCtrl.stageZoom;
					var steps:Float = arg(e, 'duration') ?? 4.0;
					var easeName:String = arg(e, 'ease') ?? 'expoOut';
					var isInstant = silent || steps <= 0;
					var duration = isInstant ? 0.0 : stepsToSeconds(steps);
					var ease = isInstant ? null : EventManager.easeByName(easeName);
					camCtrl.zoomTo(zoom, duration, ease);

				case 'Change Scroll Speed':
					var v = Std.parseFloat(Std.string(arg(e, 'speed')));
					if (!Math.isNaN(v))
						speed = v;

				case 'Change BPM':
					var v = Std.parseFloat(Std.string(arg(e, 'bpm')));
					if (!Math.isNaN(v) && v > 0)
						bpm = v;

				case 'Play Anim':
					if (!silent) {
						var id:String = arg(e, 'char');
						var anim:String = arg(e, 'anim');
						if (id != null && anim != null)
							chars.get(id).playAnim(anim, true);
					}
			}
		} catch (err:Dynamic) {
			lastError = '${e.name}: $err';
			Console.log('PreviewEvents: event "${e.name}" failed: $err', true);
		}
	}

	public function update(elapsed:Float):Void {
		if (!follow || camCtrl == null)
			return;
		camCtrl.update(elapsed);
	}

	public function snapNow():Void {
		if (camCtrl == null)
			return;
		if (camCtrl.char != null) {
			var p = camCtrl.char.getCamPosition();
			camCtrl.snapCameraTo(p.x + camCtrl.focusX, p.y + camCtrl.focusY);
		}
	}

	public function describe():String {
		var who:String = '-';
		if (camCtrl != null) {
			if (camCtrl.isLock)
				who = 'locked';
			else if (!camCtrl.existsCamEvents)
				who = 'auto';
			else
				who = lastEventChar;
		}

		var text:String = 'Camera: ' + (follow ? who : 'off') + '  ·  Speed ' + speed + '  ·  BPM ' + bpm;
		if (lastEvent != '')
			text += '  ·  Last: ' + lastEvent;

		var swapped:Bool = false;
		for (c in charData) {
			if (currentNames.get(c.id) != c.name)
				swapped = true;
		}
		if (swapped)
			text += '\nCharacters: ' + [for (c in charData) '${c.id}=${currentNames.get(c.id)}'].join('  ·  ');
		if (lastError != '')
			text += '\nERROR ' + lastError;
		return text;
	}

	public function destroy():Void {
		camCtrl?.destroy();
		camCtrl = null;
		cam = null;
		chars = null;
		onCharChanged = null;
	}
}

package modding.editors.gameplay;

import core.json.song.SongData.EventsData;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import game.controllers.CharacterController;
import game.objects.sprites.Character;

class PreviewEvents {
	public var follow:Bool = true;

	var cam:FlxCamera;
	var chars:CharacterController;
	var charData:Array<core.json.song.SongData.CharDataJson> = [];
	var onCharChanged:Character->Void;

	var events:Array<EventsData> = [];
	var index:Int = 0;

	var point:FlxPoint = FlxPoint.get();
	var camChar:Character = null;
	var camCharId:String = '';
	var locked:Bool = false;
	var hasCamEvents:Bool = false;
	var snap:Bool = true;

	var currentNames:Map<String, String> = new Map();
	var speed:Float = 1;
	var bpm:Float = 120;
	var lastEvent:String = '';

	public var lastError:String = '';

	public function new(onCharChanged:Character->Void) {
		this.onCharChanged = onCharChanged;
	}

	public function attach(cam:FlxCamera, chars:CharacterController, charData:Array<core.json.song.SongData.CharDataJson>, speed:Float, bpm:Float):Void {
		this.cam = cam;
		this.chars = chars;
		this.charData = charData ?? [];
		this.speed = speed;
		this.bpm = bpm;

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

		events = (list ?? []).copy();
		events.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
		index = 0;

		for (c in charData) {
			if (currentNames.get(c.id) != c.name) {
				var char = charOf(c.id);
				if (char != null) {
					try {
						char.changeCharacter(c.name);
						onCharChanged(char);
					} catch (e:Dynamic) {
						lastError = 'restore ${c.id}: $e';
						Trace.traceOnce('PreviewEvents: could not restore "${c.name}": $e', true);
					}
				}
				currentNames.set(c.id, c.name);
			}
		}

		hasCamEvents = false;
		locked = false;
		camCharId = opponentId();
		camChar = charOf(camCharId);
		lastEvent = '';

		while (index < events.length && events[index].time <= pos) {
			fire(events[index], true);
			index++;
		}

		snap = true;
	}

	public function advance(pos:Float):Void {
		while (index < events.length && events[index].time <= pos) {
			fire(events[index], false);
			index++;
		}
	}

	public function noteSung(char:Character):Void {
		if (!hasCamEvents && char != null)
			camChar = char;
	}

	function arg(e:EventsData, key:String):Dynamic {
		return e.arguments == null ? null : Reflect.field(e.arguments, key);
	}

	function fire(e:EventsData, silent:Bool):Void {
		lastEvent = e.name;
		try {
			switch (e.name) {
				case 'Change Character':
					var id:String = arg(e, 'char');
					var name:String = arg(e, 'newCharacter');
					var char = charOf(id);
					if (char != null && name != null) {
						char.changeCharacter(name);
						currentNames.set(id, name);
						onCharChanged(char);
					}
				case 'Camera Follow':
					var char = charOf(arg(e, 'char'));
					if (char != null) {
						hasCamEvents = true;
						camChar = char;
						camCharId = arg(e, 'char');
					}
				case 'Center Camera':
					var a = charOf(arg(e, 'char1'));
					var b = charOf(arg(e, 'char2'));
					if (a != null && b != null) {
						hasCamEvents = true;
						var pa = a.getCamPosition();
						var pb = b.getCamPosition();
						point.set((pa.x + pb.x) / 2, (pa.y + pb.y) / 2);
						locked = arg(e, 'isLock') == true;
					}
				case 'Change Scroll Speed':
					var v = Std.parseFloat(Std.string(arg(e, 'speed')));
					if (!Math.isNaN(v))
						speed = v;
				case 'Change BPM':
					var v = Std.parseFloat(Std.string(arg(e, 'bpm')));
					if (!Math.isNaN(v) && v > 0)
						bpm = v;
				case 'Play Special Anim':
					if (!silent) {
						var id:String = arg(e, 'char');
						var anim:String = arg(e, 'anim');
						if (id != null && anim != null)
							chars.playSpecialAnim(id, anim);
					}
			}
		} catch (err:Dynamic) {
			lastError = '${e.name}: $err';
			Trace.traceOnce('PreviewEvents: event "${e.name}" failed: $err', true);
		}
	}

	public function update(elapsed:Float):Void {
		if (!follow || cam == null || chars == null)
			return;

		if (!locked && camChar != null) {
			var p = camChar.getCamPosition();
			point.set(p.x, p.y);
		}

		var tx:Float = point.x - cam.width * 0.5;
		var ty:Float = point.y - cam.height * 0.5;

		if (snap) {
			cam.scroll.set(tx, ty);
			snap = false;
		} else {
			var k:Float = 1 - Math.pow(1 - 0.04, elapsed * 60);
			cam.scroll.x += (tx - cam.scroll.x) * k;
			cam.scroll.y += (ty - cam.scroll.y) * k;
		}
	}

	public function snapNow():Void {
		snap = true;
	}

	public function describe():String {
		var who:String = '-';
		if (locked)
			who = 'locked';
		else if (!hasCamEvents && camChar != null)
			who = 'auto';
		else if (camChar != null)
			who = camCharId;
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
		point.put();
		cam = null;
		chars = null;
		onCharChanged = null;
	}
}
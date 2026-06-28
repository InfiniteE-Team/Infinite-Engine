package game.modchart;

// credits to OG Framework - https://github.com/Slushi-Github/SL_ALEModchartFramework by Slushi
import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import game.controllers.NoteController;
import game.objects.sprites.notes.StrumNote;
import game.modchart.BaseModifier.ModResult;
import core.rhythm.RhythmCore;

typedef PreparedMod = {
	tag:String,
	strumIndex:Int,
	instance:BaseModifier
}

typedef ScheduledEvent = {
	beat:Float,
	callback:Void->Void,
	executed:Bool
}

class ModchartSystem extends FlxBasic {
	public var showLogs:Bool = false;

	// local length Z
	public var focalLength:Float = 500.0;

	var _nc:NoteController;

	var _mods:Map<String, PreparedMod> = new Map();
	var _modList:Array<PreparedMod> = [];
	var _activeMods:Array<PreparedMod> = [];

	var _tweens:Array<ModifierTween> = [];
	var _events:Array<ScheduledEvent> = [];
	var _eventsDirty:Bool = false;

	var _baseX:Array<Float> = [];
	var _baseY:Array<Float> = [];
	var _baseScaleX:Array<Float> = [];
	var _baseScaleY:Array<Float> = [];
	var _baseAngle:Array<Float> = [];
	var _baseAlpha:Array<Float> = [];
	var _currentZ:Array<Float> = [];

	var _wasZActive:Bool = false;

	public function new(nc:NoteController) {
		super();
		_nc = nc;
	}

	public function cacheStrumBase():Void {
		_baseX = [];
		_baseY = [];
		_baseScaleX = [];
		_baseScaleY = [];
		_baseAngle = [];
		_baseAlpha = [];
		_currentZ = [];

		for (i in 0..._nc.strums.length) {
			final s = _nc.strums.members[i];
			if (s == null)
				continue;
			_baseX[i] = s.x;
			_baseY[i] = s.y;
			_baseScaleX[i] = s.scale.x;
			_baseScaleY[i] = s.scale.y;
			_baseAngle[i] = s.angle;
			_baseAlpha[i] = s.alpha;
			_currentZ[i] = 0.0;
		}
	}

	public function prepareMod(tag:String, factory:Dynamic, strumIndex:Int = -1):Void {
		if (tag == null || tag == '' || factory == null || !Reflect.isFunction(factory))
			return;
		if (_mods.exists(tag))
			return;

		final result:Dynamic = Reflect.callMethod(null, factory, []);
		final inst:BaseModifier = Std.isOfType(result, BaseModifier) ? cast result : null;
		if (inst == null) {
			Trace.traceOnce('[ModchartSystem] prepareMod("$tag"): factory did not return a BaseModifier', true);
			return;
		}
		inst.system = this;
		inst.strumIndex = strumIndex;

		final modchart:PreparedMod = {tag: tag, strumIndex: strumIndex, instance: inst};
		_mods.set(tag, modchart);
		_modList.push(modchart);
	}

	public function setMod(beat:Float, props:Dynamic):Void {
		if (props == null)
			return;
		scheduleEvent(beat, function() {
			for (tag in Reflect.fields(props)) {
				if (!_mods.exists(tag))
					continue;
				_mods.get(tag).instance.value = Reflect.field(props, tag);
				_mods.get(tag).instance.markDirty();
			}
		});
	}

	public function easeMod(beat:Float, duration:Float, easeFunc:Dynamic, props:Dynamic):Void {
		if (props == null || duration < 0 || easeFunc == null || !Reflect.isFunction(easeFunc))
			return;
		scheduleEvent(beat, function() {
			for (tag in Reflect.fields(props)) {
				if (!_mods.exists(tag))
					continue;
				final mod = _mods.get(tag).instance;
				final toValue = Reflect.field(props, tag);
				_tweens.push(new ModifierTween(mod, 'value', mod.value, toValue, duration, beat, easeFunc));
			}
		});
	}

	public function setModSub(tag:String, beat:Float, props:Dynamic):Void {
		if (tag == null || tag == '' || props == null)
			return;
		scheduleEvent(beat, function() {
			if (!_mods.exists(tag))
				return;
			final mod = _mods.get(tag).instance;
			for (field in Reflect.fields(props)) {
				if (!mod.hasSubValue(field))
					continue;
				mod.setSubValue(field, Reflect.field(props, field));
			}
			mod.markDirty();
		});
	}

	public function easeModSub(tag:Null<String>, beat:Null<Float>, duration:Null<Float>, easeFunc:Null<Float->Float>, props:Dynamic):Void {
		if (tag == null || tag == '' || duration == null || duration < 0 || easeFunc == null || props == null)
			return;
		scheduleEvent(beat, function() {
			if (!_mods.exists(tag))
				return;
			final mod = _mods.get(tag).instance;
			for (field in Reflect.fields(props)) {
				if (!mod.hasSubValue(field))
					continue;
				_tweens.push(new ModifierTween(mod, field, mod.getSubValue(field), Reflect.field(props, field), duration, beat, easeFunc));
			}
		});
	}

	public function removeMod(tag:String):Void {
		final modchart = _mods.get(tag);
		if (modchart != null) {
			_modList.remove(modchart);
			_activeMods.remove(modchart);
		}
		_mods.remove(tag);
	}

	public function scheduleEvent(beat:Float, cb:Void->Void):Void {
		_events.push({beat: beat, callback: cb, executed: false});
		_eventsDirty = true;
	}

	public function getCurrentBeat():Float {
		if (RhythmCore.crochet > 0)
			return RhythmCore.songPosition / RhythmCore.crochet;
		return 0.0;
	}

	public function evaluateForPoint(lane:Int, beat:Float):ModResult {
		var rx = 0.0, ry = 0.0, rz = 0.0;
		var rangle = 0.0;
		var ralpha = 1.0;
		var rsx = 1.0, rsy = 1.0;
		var rspeed = Math.NaN;

		for (modchart in _modList) {
			if (modchart == null || modchart.instance == null)
				continue;
			if (!modchart.instance.isActive())
				continue;
			if (modchart.strumIndex != -1 && modchart.strumIndex != lane)
				continue;

			final r = modchart.instance.calculate(beat, lane);
			if (r == null)
				continue;

			rx += r.x;
			ry += r.y;
			rz += r.z;
			rangle += r.angle;
			ralpha *= r.alpha;
			rsx *= r.scaleX;
			rsy *= r.scaleY;
			if (!Math.isNaN(r.speed))
				rspeed = Math.isNaN(rspeed) ? r.speed : rspeed * r.speed;
		}

		return {
			x: rx,
			y: ry,
			z: rz,
			angle: rangle,
			alpha: ralpha,
			scaleX: rsx,
			scaleY: rsy,
			speed: rspeed
		};
	}

	public function getBaseX(idx:Int):Float
		return _baseX[idx] ?? 0.0;

	public function getBaseY(idx:Int):Float
		return _baseY[idx] ?? 0.0;

	public function getStrumCount():Int
		return _nc.strums.length;

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		if (!active)
			return;

		if (_eventsDirty) {
			_events.sort((a, b) -> a.beat < b.beat ? -1 : a.beat > b.beat ? 1 : 0);
			_eventsDirty = false;
		}

		final beat = getCurrentBeat();

		var i = 0;
		while (i < _events.length) {
			final events = _events[i];
			if (events == null || events.executed) {
				_events.splice(i, 1);
				continue;
			}
			if (beat >= events.beat) {
				if (events.callback != null)
					events.callback();
				events.executed = true;
				_events.splice(i, 1);
				continue;
			}
			break;
		}

		for (tween in _tweens)
			if (tween != null && tween.active)
				tween.update(beat);

		var j = _tweens.length - 1;
		while (j >= 0) {
			if (_tweens[j] != null && _tweens[j].finished)
				_tweens.splice(j, 1);
			j--;
		}

		_applyToStrums(beat);

		for (modchart in _modList)
			if (modchart != null && modchart.instance != null)
				modchart.instance.finishFrame();
	}

	function _applyToStrums(beat:Float):Void {
		_activeMods.resize(0);
		for (modchart in _modList)
			if (modchart != null && modchart.instance != null && modchart.instance.isActive())
				_activeMods.push(modchart);

		var hasZ = false;
		var rspeed = Math.NaN;

		for (i in 0..._nc.strums.length) {
			final strum = _nc.strums.members[i];
			if (strum == null)
				continue;

			final bx = _baseX[i] ?? strum.x;
			final by = _baseY[i] ?? strum.y;
			final bsx = _baseScaleX[i] ?? strum.scale.x;
			final bsy = _baseScaleY[i] ?? strum.scale.y;
			final ba = _baseAngle[i] ?? strum.angle;
			final bal = strum.alpha;

			var rx = 0.0, ry = 0.0, rz = 0.0;
			var rangle = 0.0;
			var ralpha = 1.0;
			var rsx = 1.0, rsy = 1.0;

			for (modchart in _activeMods) {
				if (modchart.strumIndex != -1 && modchart.strumIndex != i)
					continue;
				final r = modchart.instance.calculate(beat, i);
				if (r == null)
					continue;

				rx += r.x;
				ry += r.y;
				rz += r.z;
				rangle += r.angle;
				ralpha *= r.alpha;
				rsx *= r.scaleX;
				rsy *= r.scaleY;

				if (!Math.isNaN(r.speed))
					rspeed = Math.isNaN(rspeed) ? r.speed : rspeed * r.speed;
			}

			_currentZ[i] = rz;
			if (rz != 0)
				hasZ = true;

			var finalX = bx + rx;
			var finalY = by + ry;
			var finalSX = bsx * rsx;
			var finalSY = bsy * rsy;

			// Z offsets
			if (rz != 0) {
				final scale = focalLength / (focalLength + rz);
				finalX += (bx + rx - FlxG.width * 0.5) * (scale - 1);
				finalY += (by + ry - FlxG.height * 0.5) * (scale - 1);
				finalSX *= scale;
				finalSY *= scale;
			}

			strum.x = finalX;
			strum.y = finalY;
			strum.angle = ba + rangle;
			strum.alpha = bal * ralpha;
			strum.scale.set(finalSX, finalSY);
		}

		if (hasZ || _wasZActive) {
			final zBySprite = new Map<StrumNote, Float>();
			for (i in 0..._nc.strums.length) {
				final s = _nc.strums.members[i];
				if (s != null)
					zBySprite.set(s, _currentZ[i] ?? 0.0);
			}
			_nc.strums.members.sort((a, b) -> {
				if (a == null || b == null)
					return 0;
				final zA = zBySprite.get(a) ?? 0.0;
				final zB = zBySprite.get(b) ?? 0.0;
				if (zA == zB)
					return 0;
				return zA > zB ? -1 : 1;
			});
			_wasZActive = hasZ;
		}

		if (!Math.isNaN(rspeed))
			_nc.scrollSpeed = rspeed;
	}

	public function clearAll():Void {
		_mods.clear();
		_modList = [];
		_activeMods = [];
		_tweens = [];
		_events = [];
	}

	override public function destroy():Void {
		clearAll();
		super.destroy();
	}
}

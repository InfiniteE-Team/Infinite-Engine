package game.modchart;
// credits to OG Framework - https://github.com/Slushi-Github/SL_ALEModchartFramework by Slushi
typedef ModResult = {
	x:Float,
	y:Float,
	z:Float,
	angle:Float,
	scaleX:Float,
	scaleY:Float,
	alpha:Float,
	speed:Float
}

class BaseModifier {
	public var name:String;

	public var value:Float = 0.0;

	public var subValues:Map<String, Float>;

	public var system:ModchartSystem;

	public var strumIndex:Int = -1;

	// cache lanes
	var _cachedResults:Array<ModResult> = [];
	var _lastBeats:Array<Float> = [];
	var _dirty:Bool = true;

	public function new(name:String) {
		this.name = name;
		this.subValues = new Map();
		initDefaults();
	}

	public function initDefaults():Void {}

	public function isActive():Bool {
		return value != 0.0;
	}

	// calculate by beats and lanes notes
	public function calculate(beat:Float, lane:Int):ModResult {
		if (_cachedResults[lane] == null) {
			_cachedResults[lane] = _defaultResult();
			_lastBeats[lane] = -9999.0;
		}

		final r = _cachedResults[lane];

		if (!isActive()) {
			_resetResult(r);
			return r;
		}

		if (!_dirty && beat == _lastBeats[lane])
			return r;

		_resetResult(r);
		applyMod(r, beat, lane);
		_lastBeats[lane] = beat;
		return r;
	}

	public function finishFrame():Void {
		_dirty = false;
	}

	public function applyMod(r:ModResult, beat:Float, lane:Int):Void {}

	// Sub-values API

	public function getSubValue(name:String):Float {
		return subValues.exists(name) ? subValues.get(name) : 0.0;
	}

	public function setSubValue(name:String, v:Float):Void {
		if (subValues.get(name) == v)
			return;
		subValues.set(name, v);
		markDirty();
	}

	public function hasSubValue(name:String):Bool {
		return subValues.exists(name);
	}

	public function markDirty():Void {
		_dirty = true;
	}

	inline function _defaultResult():ModResult {
		return {
			x: 0,
			y: 0,
			z: 0,
			angle: 0,
			scaleX: 1,
			scaleY: 1,
			alpha: 1,
			speed: Math.NaN
		};
	}

	inline function _resetResult(r:ModResult):Void {
		r.x = 0;
		r.y = 0;
		r.z = 0;
		r.angle = 0;
		r.scaleX = 1;
		r.scaleY = 1;
		r.alpha = 1;
		r.speed = Math.NaN;
	}
}

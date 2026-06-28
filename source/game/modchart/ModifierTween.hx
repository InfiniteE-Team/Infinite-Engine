package game.modchart;
// credits to OG Framework - https://github.com/Slushi-Github/SL_ALEModchartFramework by Slushi

class ModifierTween {
	public var mod:BaseModifier;

	public var property:String;

	public var startValue:Float;
	public var endValue:Float;

	public var duration:Float;

	public var startBeat:Float;

	public var ease:Float->Float;

	public var active:Bool = true;
	public var finished:Bool = false;

	public function new(mod:BaseModifier, property:String, startValue:Float, endValue:Float, duration:Float, startBeat:Float, ease:Float->Float) {
		this.mod = mod;
		this.property = property;
		this.startValue = startValue;
		this.endValue = endValue;
		this.duration = duration;
		this.startBeat = startBeat;
		this.ease = ease;
	}

	public function update(currentBeat:Float):Void {
		if (!active || finished)
			return;

		var elapsed = currentBeat - startBeat;
		if (elapsed >= duration) {
			elapsed = duration;
			finished = true;
		}

		final t = elapsed / duration;
		final eased = ease(t);
		final current = startValue + (endValue - startValue) * eased;

		if (property == "value")
			mod.value = current;
		else
			mod.setSubValue(property, current);

		mod.markDirty();
	}
}

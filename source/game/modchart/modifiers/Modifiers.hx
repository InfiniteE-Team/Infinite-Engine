package game.modchart.modifiers;
// credits to OG Framework - https://github.com/Slushi-Github/SL_ALEModchartFramework by Slushi
import game.modchart.BaseModifier;

class DrunkModifier extends BaseModifier {
	public function new() {
		super("drunk");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.x += Math.sin(beat * 1.5 + lane * 0.8) * 120.0 * value;
}

class TanDrunkModifier extends BaseModifier {
	public function new() {
		super("tandrunk");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		final t = Math.tan(beat * 0.8 + lane * 0.5);
		r.x += Math.max(-2.0, Math.min(2.0, t)) * 80.0 * value;
	}
}

class TornadoModifier extends BaseModifier {
	public function new() {
		super("tornado");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		final wave = Math.cos(lane * 1.2 + beat * 0.5);
		r.x += wave * 130.0 * value;
	}
}

class BeatXModifier extends BaseModifier {
	public function new() {
		super("beatx");
		subValues.set("period", 1.0);
		subValues.set("offset", 0.0);
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		final period = getSubValue("period");
		final offset = getSubValue("offset");
		final t = (beat + offset + lane * 0.25) / Math.max(0.01, period);
		r.x += Math.sin(t * Math.PI * 2.0) * 100.0 * value;
	}
}

class TipsyModifier extends BaseModifier {
	public function new() {
		super("tipsy");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.y += Math.sin(beat * 1.0 + lane * 0.5) * 60.0 * value;
}

class TipsyZModifier extends BaseModifier {
	public function new() {
		super("tipsyz");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.z += Math.sin(beat * 1.2 + lane * 0.7) * 80.0 * value;
}

class ReverseModifier extends BaseModifier {
	public function new() {
		super("reverse");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		if (system == null)
			return;
		final by = system.getBaseY(lane);
		r.y += (FlxG.height - 100 - by) * 2.0 * value;
	}
}

class FlipModifier extends BaseModifier {
	public function new() {
		super("flip");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		if (system == null)
			return;
		final count = system.getStrumCount();
		if (count < 2)
			return;
		final first = system.getBaseX(0);
		final last = system.getBaseX(count - 1);
		final mid = (first + last) * 0.5;
		final bx = system.getBaseX(lane);
		r.x += (mid - bx) * 2.0 * value;
	}
}

class ShrinkXModifier extends BaseModifier {
	public function new() {
		super("shrinkx");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		if (system == null)
			return;
		final count = system.getStrumCount();
		if (count < 2)
			return;
		final mid = (system.getBaseX(0) + system.getBaseX(count - 1)) * 0.5;
		r.x += (mid - system.getBaseX(lane)) * value;
	}
}

class ConfusionModifier extends BaseModifier {
	public function new() {
		super("confusion");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.angle += beat * 180.0 * value;
}

class ConfusionOffsetModifier extends BaseModifier {
	public function new() {
		super("confusionoffset");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.angle += (beat * 180.0 + lane * 90.0) * value;
}

class TwirlModifier extends BaseModifier {
	public function new() {
		super("twirl");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.angle += Math.sin(beat + lane * 0.5) * 90.0 * value;
}

class ShakyModifier extends BaseModifier {
	public function new() {
		super("shaky");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		final seed = Math.sin(beat * 73.13 + lane * 17.31);
		r.x += seed * 20.0 * value;
		r.angle += seed * 15.0 * value;
	}
}

class MiniModifier extends BaseModifier {
	public function new() {
		super("mini");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		final s = 1.0 - value * 0.5;
		r.scaleX *= s;
		r.scaleY *= s;
	}
}

class PulseModifier extends BaseModifier {
	public function new() {
		super("pulse");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		final pulse = 1.0 + Math.sin(beat * Math.PI * 2.0) * 0.2 * value;
		r.scaleX *= pulse;
		r.scaleY *= pulse;
	}
}

class StealthModifier extends BaseModifier {
	public function new() {
		super("stealth");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.alpha *= 1.0 - value;
}

class BlinkModifier extends BaseModifier {
	public function new() {
		super("blink");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.alpha *= (Math.floor(beat) % 2 == 0) ? value : 1.0 - value * 0.8;
}

//  Z AXIS
class ZModifier extends BaseModifier {
	public function new() {
		super("z");
	}

	override function applyMod(r:ModResult, beat:Float, lane:Int)
		r.z += value * 200.0;
}

class SpeedModifier extends BaseModifier {
	public function new() {
		super("speed");
	}

	override function isActive():Bool
		return value != 1.0;

	override function applyMod(r:ModResult, beat:Float, lane:Int) {
		if (lane == 0)
			r.speed = value; // solo lo aplica una vez (lane 0)
	}
}

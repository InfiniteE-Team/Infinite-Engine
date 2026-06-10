package game.modchart;

import core.json.song.modcharts.ModChartOffset;
import game.PlayState;
import game.objects.sprites.notes.Note;
import game.objects.sprites.notes.NoteSustain;
import game.objects.sprites.notes.StrumNote;
import game.controllers.NoteController;
import game.PlayStateConfig;
import core.rhythm.RhythmCore;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import core.json.song.modcharts.ModChartEntry;
import core.json.song.modcharts.ModChartOffset;

class ModChartHelp {
	public static var instance:ModChartHelp;

	var ps:PlayState;

	public var modCharts:Array<ModChartEntry> = [];

	public static final ZERO_OFFSET = {
		x: 0.0,
		y: 0.0,
		angle: 0.0,
		alpha: 1.0,
		scaleX: 1.0,
		scaleY: 1.0
	};

	var strumBaseX:Array<Float> = [];
	var strumBaseY:Array<Float> = [];

	var totalCols:Int = 0;

	public function new(playState:PlayState) {
		this.ps = playState;
		instance = this;
	}

	public function set(name:String, value:Float, col:Int = -1):Void {
		name = name.toLowerCase();
		for (m in modCharts) {
			if (m.name == name && m.col == col) {
				m.value = value;
				return;
			}
		}
		modCharts.push({name: name, value: value, col: col});
	}

	public function remove(name:String, col:Int = -1):Void {
		name = name.toLowerCase();
		modCharts = modCharts.filter(m -> !(m.name == name && m.col == col));
	}

	public function ease(name:String, from:Float, to:Float, duration:Float, ?easeName:String, col:Int = -1):Void {
		set(name, from, col);
		FlxTween.num(from, to, duration, {ease: utils.InfiniteUtil.resolveEase(easeName)}, function(v:Float) set(name, v, col));
	}

	public function get(name:String, col:Int = -1):Float {
		for (m in modCharts)
			if (m.name == name.toLowerCase() && m.col == col)
				return m.value;
		return 0.0;
	}

	public function clear():Void
		modCharts = [];

	public function cacheStrumBase():Void {
		if (ps.noteController == null)
			return;
		strumBaseX = [];
		strumBaseY = [];
		totalCols = 0;
		for (strum in ps.noteController.strums.members) {
			if (strum == null)
				continue;
			strumBaseX.push(strum.x);
			strumBaseY.push(strum.y);
			totalCols++;
		}
	}

	public function applyToNote(note:Note, songTime:Float):Void {
		var col = note.direction;
		if (col < 0 || col >= strumBaseX.length)
			return;

		var beat = RhythmCore.songPosition / RhythmCore.crochet;
		var dist = getNoteDist(note, songTime);
		var off = evalModCharts(col, beat, dist);

		note.x += off.x;
		note.y += off.y;
		note.angle = off.angle;
		note.alpha = off.alpha;
		note.scale.x = off.scaleX;
		note.scale.y = off.scaleY;
	}

	public function applyToSustain(sustain:NoteSustain, songTime:Float):Void {
		var col = sustain.direction;
		if (col < 0 || col >= strumBaseX.length)
			return;

		var beat = RhythmCore.songPosition / RhythmCore.crochet;
		var dist = getNoteDist(sustain, songTime);
		var off = evalModCharts(col, beat, dist);

		sustain.x += off.x;
		sustain.angle = off.angle;
		sustain.alpha = off.alpha;
	}

	public function applyToStrums(songTime:Float):Void {
		if (ps.noteController == null)
			return;
		var beat = RhythmCore.songPosition / RhythmCore.crochet;
		var i = 0;
		for (strum in ps.noteController.strums.members) {
			if (strum == null) {
				i++;
				continue;
			}
			var col = i;
			var baseX = col < strumBaseX.length ? strumBaseX[col] : strum.x;
			var baseY = col < strumBaseY.length ? strumBaseY[col] : strum.y;

			var off = evalModCharts(col, beat, 0.0);
			strum.x = baseX + off.x;
			strum.y = baseY + off.y;
			strum.angle = off.angle;
			strum.alpha = off.alpha;
			i++;
		}
	}

	function evalModCharts(col:Int, beat:Float, dist:Float):ModChartOffset {
        var ox:Float = 0; var oy:Float = 0;
        var oa:Float = 0; var oAlpha:Float = 1.0;
        var oSX:Float = 1.0; var oSY:Float = 1.0;

        for (m in modCharts) {
            if (m.value == 0) continue;
            if (m.col != -1 && m.col != col) continue;

            switch (m.name) {

                // Position

                case "drunk":
                    // Horizontal sine wave, offset per column
                    ox += Math.sin(beat * 1.5 + col * 0.8) * 120.0 * m.value;

                case "tipsy":
                    // Smooth vertical wave
                    oy += Math.sin(beat * 1.0 + col * 0.5) * 60.0 * m.value;

                case "bumpy":
                    // Fastest vertical wave based on distance
                    oy += Math.sin(dist * 0.02 + beat) * 80.0 * m.value;

                case "tornado":
                    // Spiral: X oscillates more strongly near the receiver
                    var wave = Math.cos(dist * 0.015 + col * 1.2 + beat * 0.5);
                    ox += wave * 130.0 * m.value;

                case "zigzag":
                    // Distance-based zigzag
                    var t = dist * 0.01;
                    ox += (Math.floor(t) % 2 == 0 ? t - Math.floor(t) : 1.0 - (t - Math.floor(t)))
                          * 100.0 * m.value - 50.0 * m.value;

                case "spiral":
                    // Helical rotation: X and Y based on distance
                    var r = dist * 0.018;
                    ox += Math.cos(r + col * 1.57) * 90.0 * m.value;
                    oy += Math.sin(r + col * 1.57) * 40.0 * m.value;

                case "wave":
                    // X-shaped sine wave with adjustable frequency
                    ox += Math.sin(dist * 0.025 + beat * 0.8) * 100.0 * m.value;

                case "bounce":
                    // Notes "bounce" vertically
                    oy += Math.abs(Math.sin(dist * 0.02 + beat)) * 80.0 * m.value;

                case "invert":
                    // Invert X with respect to the center of the strum
                    ox += -dist * 0.1 * m.value; // pushes to the opposite side

                // Position receptors

                case "reverse":
                    // Reverse the direction of movement (notes below)
					// Implemented by moving the strum to the other vertical end
                    oy += (FlxG.height - 100 - strumBaseY[col]) * 2.0 * m.value;

                case "flip":
                    // Mirror the column horizontally with respect to the center of the group
                    if (strumBaseX.length > 0) {
                        var mid = (strumBaseX[0] + strumBaseX[strumBaseX.length - 1]) * 0.5;
                        ox += (mid - strumBaseX[col]) * 2.0 * m.value;
                    }

                case "cross":
                    // Columns 0 and 1 are swapped in X, 2 and 3 as well
                    var mirror = col % 2 == 0 ? col + 1 : col - 1;
                    if (mirror >= 0 && mirror < strumBaseX.length)
                        ox += (strumBaseX[mirror] - strumBaseX[col]) * m.value;

                case "shrinkx":
                    // Compress horizontally towards the center
                    if (strumBaseX.length > 0) {
                        var mid = (strumBaseX[0] + strumBaseX[strumBaseX.length - 1]) * 0.5;
                        ox += (mid - strumBaseX[col]) * m.value;
                    }

                // Rotation

                case "confusion":
                    // Each note rotates continuously
                    oa += beat * 180.0 * m.value;

                case "confusionoffset":
                    // Confusion with column offset (similar to SM)
                    oa += (beat * 180.0 + col * 90.0) * m.value;

                case "dizzy":
                    // Distance-based rotation
                    oa += dist * 0.1 * m.value;

                case "twirl":
                    // Sinusoidal rotation
                    oa += Math.sin(beat + col * 0.5) * 90.0 * m.value;

                // ── Visibilidad / Alpha ────────────────────────────

                case "hidden": // Notes become invisible as they approach the receiver
					// positive distance = far from the receiver
                    var t = Math.min(1.0, Math.max(0.0, dist / 300.0));
                    oAlpha *= t * m.value + (1.0 - m.value);

                case "sudden":
                    // They appear only near the receptor
                    var t = 1.0 - Math.min(1.0, Math.max(0.0, dist / 300.0));
                    oAlpha *= t * m.value + (1.0 - m.value);

                case "stealth": // alpha transparent
                    oAlpha *= 1.0 - m.value;

				// pop por rythm
                case "blink":
                    oAlpha *= (Math.floor(beat) % 2 == 0) ? m.value : 1.0 - m.value * 0.8;

                case "tiny":
                    oSX *= 1.0 - m.value * 0.7;
                    oSY *= 1.0 - m.value * 0.7;

                case "expand":
                    var t = 1.0 - Math.min(1.0, Math.max(0.0, dist / 400.0));
                    oSX *= 1.0 + t * m.value;
                    oSY *= 1.0 + t * m.value;

                case "pulsescale":
                    var pulse = 1.0 + Math.sin(beat * Math.PI * 2) * 0.2 * m.value;
                    oSX *= pulse;
                    oSY *= pulse;

                case "mini":
                    oSX *= 1.0 - m.value * 0.5;
                    oSY *= 1.0 - m.value * 0.5;
                    if (strumBaseX.length > 0) {
                        var mid = (strumBaseX[0] + strumBaseX[strumBaseX.length - 1]) * 0.5;
                        ox += (mid - strumBaseX[col]) * m.value * 0.5;
                    }
            }
        }

        return {x: ox, y: oy, angle: oa, alpha: oAlpha, scaleX: oSX, scaleY: oSY};
    }

	inline function getNoteDist(note:Note, songTime:Float):Float {
        return (note.strumTime - songTime) * ps.noteController.scrollSpeed;
    }
}

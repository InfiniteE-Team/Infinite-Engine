package game.modchart;

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
}

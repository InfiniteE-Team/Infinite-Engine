package game.modchart;

import flixel.FlxBasic;
import game.controllers.NoteController;
import game.objects.sprites.notes.NoteSustain;
import game.objects.sprites.notes.StrumNote;
import game.modchart.SustainMesh.SustainPoint;
import core.rhythm.RhythmCore;

class SustainRenderer extends FlxBasic {
	public var segments:Int = 8;

	public var enabled:Bool = true;

	var noteControl:NoteController;
	var modchart:ModchartSystem;

	var _meshes:Map<NoteSustain, SustainMesh> = new Map();

	var _pointPool:Array<SustainPoint> = [];
	var _pointPoolIdx:Int = 0;

	public function new(nc:NoteController, mc:ModchartSystem) {
		super();
		noteControl = nc;
		modchart = mc;

		final poolSize = (segments + 1) * 32;
		for (i in 0...poolSize)
			_pointPool.push(new SustainPoint(0, 0, 1));
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		if (!enabled)
			return;

		for (sustain in _meshes.keys()) {
			if (!noteControl.sustains.members.contains(sustain)) {
				_meshes.get(sustain).destroy();
				_meshes.remove(sustain);
			}
		}
	}

	override public function draw():Void {
		if (!enabled || !visible)
			return;

		final songTime = RhythmCore.songPosition;
		final beat = modchart.getCurrentBeat();
		final downscroll = noteControl.isDownscroll;

		_pointPoolIdx = 0;

		for (sustain in noteControl.sustains.members) {
			if (sustain == null || sustain.isSustainEnd)
				continue;
			if (!sustain.alive || sustain.alpha <= 0)
				continue;

			_drawSustainMesh(sustain, songTime, beat, downscroll);
		}

		super.draw();
	}

	function _drawSustainMesh(sustain:NoteSustain, songTime:Float, beat:Float, downscroll:Bool):Void {
		final lane = sustain.direction;
		final strum = sustain.strum;
		if (strum == null)
			return;

		var mesh = _meshes.get(sustain);
		if (mesh == null) {
			mesh = new SustainMesh(sustain);
			mesh.cameras = this.cameras;
			_meshes.set(sustain, mesh);
		}

		final points = _buildPoints(sustain, strum, songTime, beat, lane, downscroll);
		if (points.length < 2)
			return;

		mesh.syncWithNote();
		mesh.buildMesh(points, sustain.frameWidth * sustain.scale.x, downscroll);
		mesh.draw();
	}

	function _buildPoints(sustain:NoteSustain, strum:StrumNote, songTime:Float, beat:Float, lane:Int, downscroll:Bool):Array<SustainPoint> {
		final totalLength = sustain.length;
		if (totalLength <= 0)
			return [];

		var startTime = sustain.strumTime;
		if (sustain.isHeld && sustain.strumTime <= songTime) {
			startTime = songTime;
		}
		final endTime = sustain.strumTime + totalLength;
		if (startTime >= endTime)
			return [];

		final pts:Array<SustainPoint> = [];
		final segs = segments;

		final strumCenterX = strum.x + strum.width * 0.5;
		final baseY = modchart.getBaseY(lane);

		for (i in 0...(segs + 1)) {
			final t = i / segs;
			final noteTime = startTime + (endTime - startTime) * t;

			final dist = (noteTime - songTime) * noteControl.scrollSpeed;
			final rawY = downscroll ? baseY - dist : baseY + dist;

			final beatAtPoint = beat + (noteTime - songTime) / RhythmCore.crochet;
			final modResult = modchart.evaluateForPoint(lane, beatAtPoint);

			final finalX = strumCenterX - sustain.frameWidth * sustain.scale.x * 0.5 + modResult.x - modchart.getBaseX(lane);
			final finalY = rawY + modResult.y;
			final finalSX = strum.scale.x * modResult.scaleX;

			pts.push(_getPoint(finalX, finalY, finalSX));
		}

		return pts;
	}

	inline function _getPoint(x:Float, y:Float, sx:Float):SustainPoint {
		if (_pointPoolIdx < _pointPool.length) {
			final p = _pointPool[_pointPoolIdx++];
			p.x = x;
			p.y = y;
			p.scaleX = sx;
			return p;
		}
		_pointPool.push(new SustainPoint(x, y, sx));
		_pointPoolIdx++;
		return _pointPool[_pointPool.length - 1];
	}

	override public function destroy():Void {
		for (mesh in _meshes)
			mesh.destroy();
		_meshes.clear();
		_pointPool.resize(0);
		super.destroy();
	}
}

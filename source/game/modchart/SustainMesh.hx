package game.modchart;

import flixel.FlxStrip;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import game.objects.sprites.notes.NoteSustain;

/*
 *  Segment (6 verts, 4 triangles):
 *
 *   top-left (TL) ──── top-right (TR)
 *        │    ╲              │
 *        │      ╲            │
 *   mid-left (ML) ──── mid-right (MR)
 *        │    ╲              │
 *        │      ╲            │
 *   bot-left (BL) ──── bot-right (BR)
 */
class SustainMesh extends FlxStrip {
	public static var SEGMENTS:Int = 8;

	static final UV_BODY:Array<Float> = [
		0,   0, 1,   0, // top
		0, 0.5, 1, 0.5, // mid
		0,   1, 1, 1, // bot
	];

	static final INDICES:Array<Int> = [
		0, 1, 2, 1, 3, 2, // tri superior
		2, 3, 4, 3, 5, 4, // tri inferior
	];

	var _sustain:NoteSustain;

	public function new(sustain:NoteSustain) {
		_sustain = sustain;
		super(0, 0);

		_sustain.dirty = true;
		loadGraphic(_sustain.updateFramePixels());
		
		if (_sustain.shader != null)
			shader = _sustain.shader;

		alpha = _sustain.alpha;

		final n = SEGMENTS * 12;
		for (i in 0...n) {
			uvtData.push(0);
			vertices.push(0);
		}
		for (seg in 0...SEGMENTS) {
			final base = seg * 6;
			for (idx in INDICES)
				indices.push(base + idx);
		}
	}

	public function buildMesh(points:Array<SustainPoint>, noteW:Float, downscroll:Bool):Void {
		if (points.length < 2)
			return;

		final verts:Array<Float> = [];
		final uvs:Array<Float> = [];

		final totalSegs = points.length - 1;

		for (seg in 0...totalSegs) {
			final top = points[seg];
			final bot = points[seg + 1];

			final uvTop = seg / totalSegs;
			final uvMid = (seg + 0.5) / totalSegs;
			final uvBot = (seg + 1) / totalSegs;

			final midX = (top.x + bot.x) * 0.5;
			final midY = (top.y + bot.y) * 0.5;
			final midSX = (top.scaleX + bot.scaleX) * 0.5;
			final midW = noteW * midSX;
			final topW = noteW * top.scaleX;
			final botW = noteW * bot.scaleX;

			if (downscroll) {
				verts.push(bot.x);
				verts.push(bot.y);
				verts.push(bot.x + botW);
				verts.push(bot.y);
				verts.push(midX);
				verts.push(midY);
				verts.push(midX + midW);
				verts.push(midY);
				verts.push(top.x);
				verts.push(top.y);
				verts.push(top.x + topW);
				verts.push(top.y);
			} else {
				verts.push(top.x);
				verts.push(top.y);
				verts.push(top.x + topW);
				verts.push(top.y);
				verts.push(midX);
				verts.push(midY);
				verts.push(midX + midW);
				verts.push(midY);
				verts.push(bot.x);
				verts.push(bot.y);
				verts.push(bot.x + botW);
				verts.push(bot.y);
			}

			uvs.push(0);
			uvs.push(uvTop);
			uvs.push(1);
			uvs.push(uvTop);
			uvs.push(0);
			uvs.push(uvMid);
			uvs.push(1);
			uvs.push(uvMid);
			uvs.push(0);
			uvs.push(uvBot);
			uvs.push(1);
			uvs.push(uvBot);
		}

		vertices = new DrawData(verts.length, true, verts);
		uvtData = new DrawData(uvs.length, true, uvs);
	}

	public function syncWithNote():Void {
		if (_sustain.shader != shader)
			shader = _sustain.shader;
		alpha = _sustain.alpha;
	}
}

class SustainPoint {
	public var x:Float = 0;
	public var y:Float = 0;
	public var scaleX:Float = 1;

	public function new(x:Float, y:Float, scaleX:Float) {
		this.x = x;
		this.y = y;
		this.scaleX = scaleX;
	}
}

package core.render.swf.utils;

typedef TessResult = {vertices:Array<Float>, indices:Array<Int>};

class SWFTessellator {
	public static function tessellate(contour:SWFShapeExtractor.SWFContour, pixelSize:Float = 0.01):Null<TessResult> {
		var n = contour.length;
		if (n < 3)
			return null;

		if (signedArea(contour) < 0) {
			contour = contour.copy();
			contour.reverse();
		}

		var verts:Array<Float> = [];
		for (p in contour) {
			verts.push(p.x * pixelSize); // X
			verts.push(p.y * pixelSize); // Y
			verts.push(0.0);
		}

		var indices:Array<Int> = [];
		var idx = [for (i in 0...n) i];

		var i = 0;
		var attempts = 0;
		var maxAttempts = idx.length * idx.length;

		while (idx.length > 3 && attempts < maxAttempts) {
			var len = idx.length;
			var prev = idx[(i - 1 + len) % len];
			var curr = idx[i % len];
			var next = idx[(i + 1) % len];

			if (isEar(contour, prev, curr, next, idx)) {
				indices.push(prev);
				indices.push(curr);
				indices.push(next);
				idx.splice(i % len, 1);
				i = (i - 1 + idx.length) % idx.length;
				attempts = 0;
			} else {
				i = (i + 1) % idx.length;
				attempts++;
			}
		}

		if (idx.length == 3) {
			indices.push(idx[0]);
			indices.push(idx[1]);
			indices.push(idx[2]);
		}

		return {vertices: verts, indices: indices};
	}

	static function isEar(c:SWFShapeExtractor.SWFContour, prev:Int, curr:Int, next:Int, idx:Array<Int>):Bool {
		var ax = c[prev].x;
		var ay = c[prev].y;
		var bx = c[curr].x;
		var by = c[curr].y;
		var cx = c[next].x;
		var cy = c[next].y;
		if (cross(ax, ay, bx, by, cx, cy) <= 0)
			return false;
		for (j in idx) {
			if (j == prev || j == curr || j == next)
				continue;
			if (pointInTri(c[j].x, c[j].y, ax, ay, bx, by, cx, cy))
				return false;
		}
		return true;
	}

	static inline function cross(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Float
		return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);

	static inline function signedArea(c:SWFShapeExtractor.SWFContour):Float {
		var area = 0.0;
		for (i in 0...c.length) {
			var j = (i + 1) % c.length;
			area += c[i].x * c[j].y - c[j].x * c[i].y;
		}
		return area * 0.5;
	}

	static function pointInTri(px:Float, py:Float, ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Bool {
		var d1 = cross(px, py, ax, ay, bx, by);
		var d2 = cross(px, py, bx, by, cx, cy);
		var d3 = cross(px, py, cx, cy, ax, ay);
		return !((d1 < 0 || d2 < 0 || d3 < 0) && (d1 > 0 || d2 > 0 || d3 > 0));
	}
}

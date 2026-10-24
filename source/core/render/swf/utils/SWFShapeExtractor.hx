package core.render.swf.utils;

import openfl.display.MovieClip;
import openfl.display.Graphics;
import openfl.display._internal.DrawCommandReader;
import openfl.display._internal.DrawCommandType;
import flixel.util.FlxColor;

typedef SWFContour = Array<{x:Float, y:Float}>;
typedef SWFShape = {contour:SWFContour, color:FlxColor, isStroke:Bool, strokeWidth:Float};

class SWFShapeExtractor {
	static final BEZIER_TOLERANCE:Float = 0.5;

	public static function extract(mc:MovieClip):Array<SWFShape> {
        var shapes:Array<SWFShape> = [];
        extractFromGraphics(@:privateAccess mc.__graphics, shapes);
        return shapes;
    }

	static function extractFromGraphics(g:Graphics, out:Array<SWFShape>):Void {
		if (g == null)
			return;
		@:privateAccess var cmds = g.__commands;
		if (cmds == null || cmds.types == null || cmds.types.length == 0)
			return;

		var reader = new DrawCommandReader(cmds);
		var curContour:SWFContour = [];
		var curColor:FlxColor = FlxColor.WHITE;
		var curX:Float = 0;
		var curY:Float = 0;
		var inFill:Bool = false;

		for (type in cmds.types) {
			switch (type) {
				case BEGIN_FILL:
					var d = reader.readBeginFill();
					inFill = true;
					curColor = d.color;
					curColor.alphaFloat = d.alpha;
					curContour = [];
				case END_FILL:
					reader.readEndFill();
					if (curContour.length >= 3)
						out.push({
							contour: curContour,
							color: curColor,
							isStroke: false,
							strokeWidth: 0.0
						});
					inFill = false;
					curContour = [];
				case MOVE_TO:
					var d = reader.readMoveTo();
					curX = d.x;
					curY = d.y;
					if (inFill)
						curContour.push({x: curX, y: curY});
				case LINE_TO:
					var d = reader.readLineTo();
					curX = d.x;
					curY = d.y;
					if (inFill)
						curContour.push({x: curX, y: curY});
				case CURVE_TO:
					var d = reader.readCurveTo();
					var pts = subdivideQuadratic(curX, curY, d.controlX, d.controlY, d.anchorX, d.anchorY, BEZIER_TOLERANCE);
					if (inFill)
						for (p in pts)
							curContour.push(p);
					curX = d.anchorX;
					curY = d.anchorY;
				case _:
					reader.skip(type);
			}
		}
	}

	static function subdivideQuadratic(x0:Float, y0:Float, cx:Float, cy:Float, x1:Float, y1:Float, tol:Float):SWFContour {
		var dx = x1 - x0;
		var dy = y1 - y0;
		var d = Math.abs((cx - x0) * dy - (cy - y0) * dx);
		if (d * d <= tol * (dx * dx + dy * dy))
			return [{x: x1, y: y1}];

		var mx1 = (x0 + cx) * .5;
		var my1 = (y0 + cy) * .5;
		var mx2 = (cx + x1) * .5;
		var my2 = (cy + y1) * .5;
		var mx = (mx1 + mx2) * .5;
		var my = (my1 + my2) * .5;

		var left = subdivideQuadratic(x0, y0, mx1, my1, mx, my, tol);
		var right = subdivideQuadratic(mx, my, mx2, my2, x1, y1, tol);
		return left.concat(right);
	}
}

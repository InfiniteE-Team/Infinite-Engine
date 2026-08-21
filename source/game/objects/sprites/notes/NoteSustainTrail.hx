package game.objects.sprites.notes;

import flixel.FlxSprite;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import core.assets.FunkinSprite;
import core.json.extensions.SpriteData.ObjectData;
import game.graphics.shaders.hardcode.RGBShader;
import core.json.objects.NoteSkinData;

/**
 * Triangle-mesh sustain trail.
 *
 * All vertex positions are expressed in *local space* (relative to the
 * sprite's own origin).  The `draw()` override adds `_point` (= world
 * x/y – offset) so the camera ends up with the correct world position.
 *
 * Coordinate convention (upscroll):
 *   Y = 0  → top of the trail  (earliest time / furthest away)
 *   Y > 0  → bottom of the trail (latest time / closest to strums)
 *
 * Two quads, 4 vertices each:
 *   Quad A (indices 0-3) – the repeating body tile
 *   Quad B (indices 4-7) – the hold-end cap
 */
class NoteSustainTrail extends Note {
	// Winding: two CCW triangles per quad
	static final TRIANGLE_VERTEX_INDICES:Array<Int> = [
		0,
		1,
		2,
		1,
		2,
		3, // quad A  (body)
		4,
		5,
		6,
		5,
		6,
		7 // quad B  (end cap)
	];

	public var length:Float = 0;
	public var isHeld:Bool = false;
	public var isSustainEnd:Bool = false;
	public var parentNote:NoteSustainTrail = null;

	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();

	/** Fraction of the atlas frame height that the end-cap occupies. */
	public var endOffset:Float = 0.5;

	/**
	 * Fraction of the atlas frame height at which the end-cap bottom
	 * edge sits (measured from the same origin as endOffset).
	 * Must be > endOffset.
	 */
	public var bottomClip:Float = 0.9;

	// Derived from the atlas frame – populated in setupSustainData()
	public var graphicWidth:Float = 0;

	/** Total unclipped pixel height of the body portion. */
	public var graphicHeight:Float = 0;

	// Reference to NoteController so we can read scrollSpeed / isDownscroll
	public var noteTrailControl:game.controllers.NoteController = null;

	public function new(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0, length:Float,
			?noteType:String = 'normal', isSustainEnd:Bool = false) {
		this.length = length;
		this.isSustainEnd = isSustainEnd;

		vertices = new DrawData<Float>(16, true);
		uvtData = new DrawData<Float>(16, true);

		super(strumTime, keys, x, y, noteSkinData, noteSkin, direction, noteType);

		setIndices(TRIANGLE_VERTEX_INDICES);
		setupSustainData();
	}

	public function setIndices(idx:Array<Int>):Void {
		if (indices.length == idx.length) {
			for (i in 0...idx.length)
				indices[i] = idx[i];
		} else {
			indices = new DrawData<Int>(idx.length, false, idx);
		}
	}

	public function setupSustainData():Void {
		if (graphic == null)
			return;

		// Width: 75 % of the atlas frame, matching the old code's intent
		graphicWidth = (frame != null) ? (frame.frame.width * 0.75) : 15.0;

		// Height uses the same 0.45 factor as NoteController's scrollMult,
		// so the trail pixel height matches what NoteController computes.
		// We use scrollSpeed=1.0 as the default; updateClipping multiplies
		// by the actual speed each frame.
		graphicHeight = length * 0.45;

		updateClipping(strumTime);
	}

	/**
	 * Rebuild vertex / UV data.
	 *
	 * Local-space convention (upscroll):
	 *   Y = 0        → top anchor of the sprite (world: sustain.y)
	 *   Y = totalH   → bottom of the full trail (world: sustain.y + totalH = strumMid)
	 *
	 * @param songTime    Current song position in ms.
	 * @param scrollSpeed NoteController's current scrollSpeed.
	 * @param strumMidY   World-space Y of the strum centre, used to clip the
	 *                    bottom of the trail so it never draws past the receptor.
	 *                    Pass 0 (default) to skip bottom-clipping.
	 * @param isDownscroll Pass true to flip the clipping direction.
	 */
	public function updateClipping(songTime:Float = 0, scrollSpeed:Float = 1.0, strumMidY:Float = 0, isDownscroll:Bool = false):Void {
		if (graphic == null || frame == null)
			return;

		var scrollMult:Float = 0.45 * scrollSpeed;
		var totalH:Float = length * scrollMult; // full pixel height of the body

		var remaining:Float = (strumTime + length) - songTime;
		if (remaining <= 0) {
			visible = false;
			return;
		}
		visible = true;

		var visibleH:Float = Math.min(remaining * scrollMult, totalH);

		if (strumMidY != 0) {
			if (!isDownscroll) {
				var maxVisible:Float = strumMidY - y;
				if (maxVisible <= 0) {
					visible = false;
					return;
				}
				visibleH = Math.min(visibleH, maxVisible);
			} else {
				var maxVisible:Float = y - strumMidY + totalH;
				if (maxVisible <= 0) {
					visible = false;
					return;
				}
				visibleH = Math.min(visibleH, maxVisible);
			}
		}

		// Horizontal centering — purely in local space, no world offset
		var halfW:Float = graphicWidth * 0.5;
		var x0:Float = -halfW;
		var x1:Float = halfW;

		// Body quad Y range in local space (Y=0 = top anchor = sustain.y in world)
		var bodyTop:Float = totalH - visibleH;
		var bodyBottom:Float = bodyTop + visibleH; // = totalH when fully visible

		// End-cap
		var capH:Float = graphic.height * (bottomClip - endOffset);
		var capTop:Float = totalH; // always anchored at the full bottom
		var capBot:Float = totalH + capH;

		// uvs
		var uv = frame.uv;
		var uL = uv.left;
		var uR = uv.right;
		var vT = uv.top;
		var vB = uv.bottom;

		// Bottom of body always maps to vB; top clips proportionally
		var uvTopV:Float = vB - (vB - vT) * (visibleH / totalH);

		// body
		vertices[0] = x0;
		vertices[1] = bodyTop; // v0 top-left
		vertices[2] = x1;
		vertices[3] = bodyTop; // v1 top-right
		vertices[4] = x0;
		vertices[5] = bodyBottom; // v2 bot-left
		vertices[6] = x1;
		vertices[7] = bodyBottom; // v3 bot-right

		uvtData[0] = uL;
		uvtData[1] = uvTopV; // v0
		uvtData[2] = uR;
		uvtData[3] = uvTopV; // v1
		uvtData[4] = uL;
		uvtData[5] = vB; // v2
		uvtData[6] = uR;
		uvtData[7] = vB; // v3

		// end cap
		vertices[8] = x0;
		vertices[9] = capTop; // v4 top-left
		vertices[10] = x1;
		vertices[11] = capTop; // v5 top-right
		vertices[12] = x0;
		vertices[13] = capBot; // v6 bot-left
		vertices[14] = x1;
		vertices[15] = capBot; // v7 bot-right

		var capUvTop:Float = vB - (vB - vT) * (bottomClip - endOffset);
		uvtData[8] = uL;
		uvtData[9] = capUvTop; // v4
		uvtData[10] = uR;
		uvtData[11] = capUvTop; // v5
		uvtData[12] = uL;
		uvtData[13] = vB; // v6
		uvtData[14] = uR;
		uvtData[15] = vB; // v7
	}

	/** Alias kept for backwards compatibility. */
	public inline function reinitSustain(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0,
			length:Float, ?noteType:String = 'normal', isSustainEnd:Bool = false):Void {
		reinitSustainTrail(strumTime, keys, x, y, noteSkinData, noteSkin, direction, length, noteType, isSustainEnd);
	}

	public function reinitSustainTrail(strumTime:Float, keys:Int, x:Float, y:Float, noteSkinData:NoteSkinData, noteSkin:String, direction:Int = 0,
			length:Float, ?noteType:String = 'normal', isSustainEnd:Bool = false):Void {
		this.length = length;
		this.isSustainEnd = isSustainEnd;
		this.isHeld = false;
		this.parentNote = null;
		this.strumTime = strumTime;

		clipRect = null;
		reinit(strumTime, keys, x, y, noteSkinData, noteSkin, direction, noteType);

		var animName = isSustainEnd ? 'note$direction-HoldEnd' : 'note$direction-Hold';
		playAnim(animName, true);
		RGBShader.applyByAnimation(this, noteSkinData, animName);
		setupSustainData();
	}

	override function loadSprite(noteSkinData:NoteSkinData) {
		loadProps(noteSkinData.props, 'game/noteskins/$noteSkin/strumnotes');
		var animName = isSustainEnd ? 'note$direction-HoldEnd' : 'note$direction-Hold';
		playAnim(animName);
		RGBShader.applyByAnimation(this, noteSkinData, animName);
	}

	@:access(flixel.FlxCamera)
	override public function draw():Void {
		if (alpha == 0 || graphic == null || vertices == null)
			return;

		for (camera in cameras) {
			if (!camera.visible || !camera.exists)
				continue;
			// The mesh vertex positions are already in world-relative space.
			// Animation offsets (applied by FunkinSprite.activeOffsets) must NOT
			// shift the mesh, so we ignore offset entirely and use (x, y) directly.
			_point.set(x, y);
			camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, colorTransform, shader);
		}
	}

	override public function destroy():Void {
		super.destroy();
	}
}

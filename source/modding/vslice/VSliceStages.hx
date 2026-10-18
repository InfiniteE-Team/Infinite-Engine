package modding.vslice;

import core.json.objects.StageData;
import core.json.extensions.SpriteData.AnimData;
import modding.vslice.VSlice.*;

// V-Slice stage jsons: props and characters sorted by zIndex into engine elements -JloorDev
class VSliceStages {
	public static function readStage(path:String):Null<StageData> {
		var raw:Dynamic = FormatJson.readJson(path);
		if (raw == null || raw.elements != null || raw.props == null)
			return raw;
		return convertStage(raw);
	}

	static function convertStage(raw:Dynamic):StageData {
		var layered:Array<{z:Float, i:Int, el:StageElement}> = [];

		for (p in (raw.props : Array<Dynamic>)) {
			var el = convertProp(p);
			if (el != null) {
				el.zIndex = Std.int(p.zIndex ?? 0);
				layered.push({z: el.zIndex, i: layered.length, el: el});
			}
		}

		var chars:Dynamic = raw.characters;
		for (role in ['gf', 'dad', 'bf']) {
			var c:Dynamic = chars != null ? Reflect.field(chars, role) : null;
			if (c == null)
				continue;
			layered.push({
				z: c.zIndex ?? 0,
				i: layered.length,
				el: {
					type: 'character',
					id: role,
					position: pair(c.position, 0),
					camPos: pair(c.cameraOffsets, 0),
					anchorFeet: true,
					alpha: c.alpha,
					zIndex: Std.int(c.zIndex ?? 0)
				}
			});
		}

		layered.sort((a, b) -> a.z != b.z ? (a.z < b.z ? -1 : 1) : a.i - b.i);

		return {
			name: raw.name ?? 'stage',
			defaultZoom: raw.cameraZoom ?? 1.0,
			elements: [for (l in layered) l.el]
		};
	}

	static function convertProp(p:Dynamic):Null<StageElement> {
		var asset:String = p.assetPath;
		if (asset == null)
			return null;

		var scale = pair(p.scale, 1);
		var name:String = p.name ?? asset;

		if (StringTools.startsWith(asset, '#')) {
			return {
				type: 'graphic',
				props: {
					name: name,
					color: asset,
					scale: scale,
					position: pair(p.position, 0),
					scrollFactor: p.scroll != null ? pair(p.scroll, 1) : null,
					alpha: p.alpha
				}
			};
		}

		var anims:Array<AnimData> = [];
		for (a in ((p.animations ?? []) : Array<Dynamic>)) {
			var indices:Array<Int> = a.frameIndices;
			anims.push({
				name: a.name,
				prefix: a.prefix,
				indices: indices != null && indices.length > 0 ? indices : null,
				offsets: [-num(a.offsets, 0) * scale[0], -num(a.offsets, 1) * scale[1]],
				looped: a.looped == true,
				framerate: a.frameRate ?? 24
			});
		}

		var has = (n:String) -> Lambda.exists(anims, a -> a.name == n);
		var bop:Array<String> = has('danceLeft') && has('danceRight') ? ['danceLeft', 'danceRight'] : (has('idle') ? ['idle'] : null);
		var start:String = p.startingAnimation ?? (anims.length > 0 ? anims[0].name : null);

		return {
			type: anims.length > 0 ? 'animated' : 'sprite',
			props: {
				name: name,
				path: stripLibrary(asset),
				folder: '',
				keepHitboxOffset: true,
				position: pair(p.position, 0),
				scrollFactor: p.scroll != null ? pair(p.scroll, 1) : null,
				scale: scale,
				alpha: p.alpha,
				flipX: p.flipX,
				flipY: p.flipY,
				blend: p.blend,
				antialiasing: p.isPixel != true,
				anims: anims,
				firstAnim: start != null && has(start) ? start : null,
				bopAnims: (p.danceEvery ?? 0) > 0 ? bop : null,
				danceEvery: p.danceEvery
			}
		};
	}
}

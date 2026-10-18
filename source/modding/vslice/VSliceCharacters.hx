package modding.vslice;

import core.assets.Library;
import core.json.objects.CharacterData;
import core.json.extensions.SpriteData.ObjectData;
import core.json.extensions.SpriteData.AnimData;
import modding.vslice.VSlice.*;

// V-Slice characters and health icons, converted to the engine format when they are read -JloorDev
class VSliceCharacters {
	public static function readCharacter(path:String):Null<CharacterData> {
		var raw:Dynamic = FormatJson.readJson(path);
		if (raw == null || raw.render != null || raw.assetPath == null || raw.animations == null)
			return raw;
		var main = stripLibrary(raw.assetPath);
		if (Library.findLib('images/$main.png') == null && Library.findLib('images/$main/Animation.json') == null) {
			Console.log('[V-Slice] ${haxe.io.Path.withoutDirectory(path)} needs "$main" from the base game, using the engine bf', true);
			return FormatJson.readJson('${Library.baseFolder}/data/characters/bf.json');
		}
		var id = haxe.io.Path.withoutExtension(path);
		var dataDir = id.indexOf('data/characters/');
		id = dataDir >= 0 ? id.substr(dataDir + 'data/characters/'.length) : haxe.io.Path.withoutDirectory(id);
		return convertCharacter(raw, id);
	}

	static function convertCharacter(raw:Dynamic, id:String):CharacterData {
		var scale:Float = raw.scale ?? 1.0;
		var isPixel:Bool = raw.isPixel == true;
		var global:Dynamic = raw.offsets;

		var anims:Array<AnimData> = [];
		for (a in (raw.animations : Array<Dynamic>)) {
			var o:Dynamic = a.offsets;
			var indices:Array<Int> = a.frameIndices;
			var anim:AnimData = {
				name: a.name,
				prefix: a.prefix,
				indices: indices != null && indices.length > 0 ? indices : null,
				offsets: [-(num(o, 0) - num(global, 0)) * scale, -(num(o, 1) - num(global, 1)) * scale],
				looped: a.looped == true,
				framerate: a.frameRate ?? 24
			};
			if (a.assetPath != null)
				anim.filePath = stripLibrary(a.assetPath);
			anims.push(anim);
		}

		var startAnim:String = raw.startingAnimation ?? 'idle';
		var layer:ObjectData = {
			name: 'char',
			path: stripLibrary(raw.assetPath),
			folder: '',
			keepHitboxOffset: true,
			anims: anims,
			scale: [scale, scale],
			flipX: raw.flipX == true,
			antialiasing: !isPixel,
			firstAnim: Lambda.exists(anims, a -> a.name == startAnim) ? startAnim : null
		};

		var cam:Dynamic = raw.cameraOffsets;
		return {
			meta: {flipAsPlayer: true},
			gameplay: {
				position: null,
				cameraOffset: [num(cam, 0), num(cam, 1)],
				singTime: (raw.singTime ?? 8.0) / 4,
				idleAfterSing: true,
				death: {character: id}
			},
			render: {layers: [layer]},
			icon: convertIcon(raw.healthIcon, haxe.io.Path.withoutDirectory(id))
		};
	}

	static function convertIcon(health:Dynamic, charId:String):Null<IconData> {
		var id:String = health?.id ?? charId;
		var flip:Bool = health?.flipX == true;
		var pixel:Bool = health?.isPixel == true;

		var path = 'icons/icon-$id';
		var png = Paths.getPath(path, 'image');
		if (png == null) {
			path = 'game/icons/$id';
			png = Paths.getPath(path, 'image');
		}
		if (png == null)
			return null;

		if (Paths.getPath('images/$path', 'xml') != null) {
			return {
				size: pixel ? null : 150,
				props: {
					name: 'icon',
					path: path,
					folder: '',
					firstAnim: 'normal',
					flipX: flip,
					antialiasing: !pixel,
					anims: [
						{name: 'normal', prefix: 'idle', looped: true, framerate: 24},
						{name: 'losing', prefix: 'losing', looped: true, framerate: 24}
					]
				}
			};
		}

		var size = pngHeight(png);
		if (size <= 0)
			return null;
		return {
			size: pixel ? null : 150,
			props: {
				name: 'icon',
				path: path,
				folder: '',
				firstAnim: 'normal',
				flipX: flip,
				antialiasing: !pixel,
				frameScale: [size, size],
				anims: [
					{name: 'normal', indices: [0], looped: false, framerate: 24},
					{name: 'losing', indices: [1], looped: false, framerate: 24}
				]
			}
		};
	}

	static function pngHeight(path:String):Int {
		try {
			var input = sys.io.File.read(path);
			var head = input.read(24);
			input.close();
			return (head.get(20) << 24) | (head.get(21) << 16) | (head.get(22) << 8) | head.get(23);
		} catch (e:Dynamic) {
			return 0;
		}
	}
}

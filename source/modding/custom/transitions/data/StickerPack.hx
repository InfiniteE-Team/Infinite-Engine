package modding.custom.transitions.data;

import core.json.engine.StickerData;

/**
 * Resolves asset paths for a sticker pack by name.
 * The pack JSON lives at:
 *   assets/data/stickers/<packName>.json
 *   mods/<mod>/data/stickers/<packName>.json
 */
class StickerPack {
	public var data:StickerData;
	public var packName:String;

	public function new(packName:String) {
		this.packName = packName;
		this.data = loadData(packName);
	}

	static function loadData(name:String):StickerData {
		var path = FormatJson.readJson(Paths.getPath('data/stickers/$name', 'json'));
		return path;
	}

	public function graphicPath(id:String):String {
		return Paths.getPath('stickers/${data.nameSkin}/$id', 'image');
	}

	public function randomId():String {
		if (data.id.length == 0)
			return null;
		return data.id[FlxG.random.int(0, data.id.length - 1)];
	}

	public function randomClickSound(count:Int = 9):String {
		var n = FlxG.random.int(1, count);
		return Paths.getPath('menus/stickersounds/$packName/keyClick$n', 'sound');
	}
}
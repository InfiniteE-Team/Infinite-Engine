package game.objects.sprites.notes;

import sys.FileSystem;
import core.assets.Library;
import modding.mods.ModsRegistry;
import modding.vslice.VSliceNoteStyles;

// Note skins as one package per name: data/noteskins/<skin>/ holds strumnotes, splashes, holdsplashes and, optional,
// popups (rating and combo images) and countdown. A "vslice-<id>" skin is a V-Slice notestyle converted on read -JloorDev
class NoteSkins {
	public static inline final DEFAULT:String = 'default';

	static var converted:Map<String, Dynamic> = new Map();

	public static function read(skin:String, part:String):Dynamic {
		if (skin == null || skin == '')
			skin = DEFAULT;
		if (StringTools.startsWith(skin, VSliceNoteStyles.PREFIX)) {
			var key = '${ModsRegistry.currentMod}|$skin|$part';
			if (!converted.exists(key))
				converted.set(key, VSliceNoteStyles.convert(skin.substr(VSliceNoteStyles.PREFIX.length), part));
			return converted.get(key);
		}
		return FormatJson.readJson(Paths.getPath('data/noteskins/$skin/$part', 'json'));
	}

	public static function exists(skin:String):Bool
		return read(skin, 'strumnotes') != null;

	public static function imageFolder(skin:String, part:String):String
		return StringTools.startsWith(skin ?? '', VSliceNoteStyles.PREFIX) ? '' : 'game/noteskins/$skin/$part/';

	public static function list():Array<String> {
		var folders = ['${Library.baseFolder}/data/noteskins'];
		if (ModsRegistry.onMod && ModsRegistry.currentMod != null && ModsRegistry.currentMod != '')
			folders.push('${Library.modsFolder}/${ModsRegistry.currentMod}/data/noteskins');
		var names:Array<String> = [];
		for (folder in folders) {
			if (!FileSystem.exists(folder) || !FileSystem.isDirectory(folder))
				continue;
			for (name in FileSystem.readDirectory(folder))
				if (!names.contains(name) && FileSystem.exists('$folder/$name/strumnotes.json'))
					names.push(name);
		}
		names.sort(Reflect.compare);
		for (name in VSliceNoteStyles.list())
			names.push(name);
		return names;
	}
}

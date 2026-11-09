package modding.vslice;

import sys.FileSystem;
import core.json.menus.FreeplayData;
import core.json.menus.storymenu.WeekData;
import core.json.extensions.SpriteData.ObjectData;
import modding.vslice.VSlice.*;

// V-Slice songs as the menus want them: freeplay list, story weeks, charts, difficulties and albums -JloorDev
class VSliceSongs {
	public static function metadata(song:String):Dynamic
		return readMod('data/songs/$song/$song-metadata.json');

	public static function chart(song:String):Dynamic
		return readMod('data/songs/$song/$song-chart.json');

	public static function difficulties(song:String):Array<String> {
		var list:Array<Dynamic> = metadata(song)?.playData?.difficulties;
		return list != null ? [for (d in list) Std.string(d)] : [];
	}

	public static function albumArt(id:String):Null<String> {
		if (id == null)
			return null;
		var art:String = readMod('data/ui/freeplay/albums/$id.json')?.albumArtAsset;
		if (art == null)
			return null;
		art = stripLibrary(art);
		return Paths.getPath(art, 'image') != null ? art : null;
	}

	static function songEntry(id:String):Null<SongData> {
		var meta:Dynamic = metadata(id);
		if (meta == null)
			return null;

		var timeChanges:Array<Dynamic> = meta.timeChanges;
		return {
			song: id,
			icon: meta.playData?.characters?.opponent,
			bpm: timeChanges != null && timeChanges.length > 0 ? timeChanges[0].bpm : null,
			artist: meta.artist,
			album: albumArt(meta.playData?.album)
		};
	}

	public static function weeks():Array<WeekData> {
		var weeks:Array<WeekData> = [];
		for (file in sortedJson('data/levels')) {
			var level:Dynamic = readMod('data/levels/$file');
			if (level == null || level.visible == false || level.songs == null)
				continue;

			var songs:Array<SongData> = [];
			for (id in (level.songs : Array<Dynamic>)) {
				var entry = songEntry(Std.string(id));
				if (entry != null)
					songs.push(entry);
			}
			if (songs.length == 0)
				continue;

			var name:String = level.name ?? file.substr(0, file.length - 5);
			weeks.push({
				week: file.substr(0, file.length - 5),
				priority: weeks.length,
				weekGraphic: level.titleAsset != null ? stripLibrary(level.titleAsset) : null,
				chars: [],
				charProps: [for (i => p in (level.props ?? [] : Array<Dynamic>)) storyProp(p, i)].filter(p -> p != null),
				color: level.background,
				description: name,
				songs: songs
			});
		}
		return weeks;
	}

	static function storyProp(prop:Dynamic, index:Int):Null<ObjectData> {
		var path = stripLibrary(prop.assetPath);
		// V-Slice's layout; its band starts at y 56, ours at 70 -JloorDev
		var position = [num(prop.offsets, 0) + FlxG.width * 0.25 * index, num(prop.offsets, 1) + 14];
		if (core.assets.Library.findLib('images/$path.png') == null) {
			// base game props aren't in the mod, use ours with the same name -JloorDev
			var engineProp:ObjectData = FormatJson.readJson(Paths.getPath('data/menus/storymenu/chars/${haxe.io.Path.withoutDirectory(path)}', 'json'));
			if (engineProp != null)
				engineProp.position = position;
			return engineProp;
		}
		var anims:Array<Dynamic> = prop.animations ?? [];
		var scale:Float = prop.scale ?? 1.0;
		return {
			name: haxe.io.Path.withoutDirectory(path),
			path: path,
			position: position,
			folder: '',
			scale: [scale, scale],
			anims: [
				for (a in anims)
					{
						name: a.name,
						prefix: a.prefix,
						indices: a.frameIndices,
						framerate: a.frameRate ?? 24,
						looped: a.looped == true
					}
			]
		};
	}

	public static function freeplay():FreeplayData {
		var ids:Array<String> = [];
		for (week in weeks())
			for (s in week.songs)
				if (!ids.contains(s.song))
					ids.push(s.song);

		var dir = '${modRoot()}/data/songs';
		if (FileSystem.exists(dir)) {
			var rest = [for (f in FileSystem.readDirectory(dir)) if (!ids.contains(f) && FileSystem.isDirectory('$dir/$f')) f];
			rest.sort(Reflect.compare);
			ids = ids.concat(rest);
		}

		var songData:Array<SongData> = [];
		for (id in ids) {
			var entry = songEntry(id);
			if (entry != null)
				songData.push(entry);
		}
		return {songData: songData};
	}
}

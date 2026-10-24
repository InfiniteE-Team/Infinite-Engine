package modding.vslice;

import core.assets.Library;
import core.json.objects.NoteSkinData;
import core.json.extensions.SpriteData.AnimData;
import modding.vslice.VSlice.*;

// V-Slice notestyles (data/notestyles/<id>.json) converted to engine skin parts; game.objects.sprites.notes.NoteSkins
// asks for them when a skin is named "vslice-<id>", so they run through the engine's own skin code -JloorDev
class VSliceNoteStyles {
	public static inline final PREFIX:String = 'vslice-';

	static final DIRS = ['left', 'down', 'up', 'right'];

	public static function skinFor(noteStyle:String):Null<String> {
		if (noteStyle == null || noteStyle == '' || noteStyle == 'funkin')
			return null;
		return readMod('data/notestyles/$noteStyle.json') != null ? PREFIX + noteStyle : null;
	}

	public static function list():Array<String> {
		var names:Array<String> = [];
		if (!VSlice.isActive())
			return names;
		for (file in sortedJson('data/notestyles'))
			names.push(PREFIX + file.substr(0, file.length - 5));
		return names;
	}

	public static function convert(styleId:String, part:String):Dynamic {
		var style:Dynamic = readMod('data/notestyles/$styleId.json');
		var assets:Dynamic = style?.assets;
		if (assets == null)
			return null;
		return switch (part) {
			case 'strumnotes': strumnotes(assets);
			case 'splashes': splashes(assets.noteSplash);
			case 'holdsplashes': holdsplashes(assets.holdNoteCover);
			case 'popups': popups(assets);
			case 'countdown': countdown(assets);
			default: null;
		};
	}

	static function prefixOf(data:Dynamic, key:String):String
		return Reflect.field(data, key)?.prefix;

	static function strumnotes(assets:Dynamic):NoteSkinData {
		var note:Dynamic = assets.note;
		var strum:Dynamic = assets.noteStrumline;
		var hold:Dynamic = assets.holdNote;
		var strumPath = stripLibrary(strum.assetPath);
		var notePath = stripLibrary(note.assetPath);
		var holdPath = hold?.assetPath != null ? stripLibrary(hold.assetPath) : null;
		var scale:Float = strum.scale ?? note.scale ?? 0.7;

		var holdSize = holdPath != null ? pngSize(Library.findLib('images/$holdPath.png')) : null;
		var holdFrame = holdSize != null ? [Std.int(holdSize[0] / 8), holdSize[1]] : null;

		var strumOffsets:Array<Dynamic> = strum.offsets ?? [0, 0];
		var strumOff = [num(strumOffsets, 0), num(strumOffsets, 1)];

		var anims:Array<AnimData> = [];
		for (i in 0...4) {
			var dir = DIRS[i];
			anims.push({
				name: 'note$i-Scroll',
				filePath: notePath,
				prefix: prefixOf(note.data, dir) + "0",
				framerate: 24,
				offsets: [0, 5]
			});
			if (holdFrame != null) {
				anims.push({
					name: 'note$i-Hold',
					filePath: holdPath,
					frameScale: holdFrame,
					indices: [i * 2],
					framerate: 24,
					offsets: [0, 0]
				});
				anims.push({
					name: 'note$i-HoldEnd',
					filePath: holdPath,
					frameScale: holdFrame,
					indices: [i * 2 + 1],
					framerate: 24,
					offsets: [0, -2]
				});
			}
			anims.push({
				name: 'static$i',
				prefix: prefixOf(strum.data, '${dir}Static'),
				framerate: 24,
				offsets: [-28 + strumOff[0], -30 + strumOff[1]]
			});
			anims.push({
				name: 'press$i',
				prefix: prefixOf(strum.data, '${dir}Press'),
				framerate: 24,
				offsets: [0 + strumOff[0], 0 + strumOff[1]]
			});
			anims.push({
				name: 'confirm$i',
				prefix: prefixOf(strum.data, '${dir}Confirm'),
				framerate: 24,
				offsets: [-28 + strumOff[0], -30 + strumOff[1]]
			});
		}

		return {
			description: 'V-Slice notestyle',
			props: {
				name: 'StrumNotes',
				path: strumPath,
				folder: '',
				position: [15 + strumOff[0], 20 + strumOff[1]],
				scale: [scale, scale],
				antialiasing: assets.note?.isPixel != true,
				anims: anims
			}
		};
	}

	static function splashes(splash:Dynamic):Dynamic {
		if (splash?.assetPath == null || splash.data?.enabled == false)
			return game.objects.sprites.notes.NoteSkins.read('default', 'splashes');
		var path = stripLibrary(splash.assetPath);
		var size = frameSize(path, null) ?? [260, 298];
		var extra:Dynamic = splash.offsets;
		var off = [
			-60 - (size[0] - 260) / 2 + num(extra, 0),
			-60 - (size[1] - 298) / 2 + num(extra, 1)
		];
		var anims:Array<AnimData> = [];
		for (i in 0...4) {
			var list:Array<Dynamic> = Reflect.field(splash.data, '${DIRS[i]}Splashes') ?? [];
			for (n in 0...2) {
				var entry:Dynamic = list.length > 0 ? list[n % list.length] : null;
				if (entry != null)
					anims.push({
						name: 'note$i-Splash$n',
						prefix: entry.prefix,
						framerate: entry.framerate ?? 24,
						looped: false,
						offsets: off
					});
			}
		}
		return {
			props: {
				name: 'Splash',
				path: path,
				folder: '',
				scale: [splash.scale ?? 1.0, splash.scale ?? 1.0],
				alpha: splash.alpha ?? 1.0,
				antialiasing: true,
				anims: anims
			}
		};
	}

	static function holdsplashes(cover:Dynamic):Dynamic {
		var data:Dynamic = cover?.data;
		if (data == null || data.enabled == false)
			return game.objects.sprites.notes.NoteSkins.read('default', 'holdsplashes');
		var extra:Dynamic = cover.offsets;
		var anims:Array<AnimData> = [];
		var firstPath:String = null;
		for (i in 0...4) {
			var d:Dynamic = Reflect.field(data, DIRS[i]);
			if (d == null)
				continue;
			var path = stripLibrary(d.assetPath ?? cover.assetPath);
			firstPath ??= path;
			var stages:Array<Array<Dynamic>> = [
				['start', 'startHold', false],
				['hold', 'loopHold', true],
				['end', 'endHold', false]
			];
			for (stage in stages) {
				var key:String = stage[0];
				var prefix:String = Reflect.field(d, key)?.prefix;
				if (prefix == null)
					continue;
				var size = frameSize(path, prefix) ?? [161, 125];
				var off = [85.5 - size[0] / 2 + num(extra, 0), 72.5 - size[1] / 2 + num(extra, 1)];
				anims.push({
					name: 'note$i-${stage[1]}',
					filePath: path,
					prefix: prefix,
					framerate: 24,
					looped: stage[2],
					offsets: off
				});
			}
		}
		if (firstPath == null)
			return game.objects.sprites.notes.NoteSkins.read('default', 'holdsplashes');
		return {
			props: {
				name: 'HoldSplash',
				path: firstPath,
				folder: '',
				scale: [1.0, 1.0],
				antialiasing: true,
				anims: anims
			}
		};
	}

	static function popups(assets:Dynamic):Dynamic {
		var entry = (a:Dynamic) -> a?.assetPath != null ? {path: stripLibrary(a.assetPath), scale: a.scale ?? 1.0, pixel: a.isPixel == true} : null;
		var ratings:Dynamic = {};
		for (r in ['sick', 'good', 'bad', 'shit']) {
			var e = entry(Reflect.field(assets, 'judgement' + r.charAt(0).toUpperCase() + r.substr(1)));
			if (e != null)
				Reflect.setField(ratings, r, e);
		}
		var numbers:Dynamic = {};
		for (n in 0...10) {
			var e = entry(Reflect.field(assets, 'comboNumber$n'));
			if (e != null)
				Reflect.setField(numbers, Std.string(n), e);
		}
		return {folder: '', ratings: ratings, numbers: numbers};
	}

	static function countdown(assets:Dynamic):Dynamic {
		var engineSounds = ['intro3', 'intro2', 'intro1', 'introGo'];
		var steps:Array<Dynamic> = [];
		var modSounds = true;
		var keys = ['countdownThree', 'countdownTwo', 'countdownOne', 'countdownGo'];
		for (i in 0...4) {
			var a:Dynamic = Reflect.field(assets, keys[i]);
			var audio:String = a?.data?.audioPath != null ? stripLibrary(a.data.audioPath) : null;
			if (audio == null || Paths.getPath(audio, 'sound') == null)
				modSounds = false;
		}
		for (i in 0...4) {
			var a:Dynamic = Reflect.field(assets, keys[i]);
			var step:Dynamic = {};
			step.sound = {name: keys[i], path: modSounds ? stripLibrary(a.data.audioPath) : engineSounds[i]};
			if (a?.assetPath != null) {
				var scale:Float = a.scale ?? 1.0;
				step.props = {
					name: keys[i],
					path: stripLibrary(a.assetPath),
					folder: '',
					position: [0.0, 0.0],
					scale: [scale, scale],
					antialiasing: a.isPixel != true
				};
			}
			steps.push(step);
		}
		return {countdown: steps, soundFolder: modSounds ? '' : 'gameplay/countdown/default/'};
	}

	static function frameSize(path:String, prefix:Null<String>):Null<Array<Float>> {
		var xml = Library.findLib('images/$path.xml');
		if (xml == null)
			return null;
		var tag = ~/<SubTexture\b[^>]*>/;
		var rest = Paths.readText(xml);
		while (tag.match(rest)) {
			var t = tag.matched(0);
			rest = tag.matchedRight();
			var name = ~/name="([^"]*)"/;
			if (prefix != null && (!name.match(t) || !StringTools.startsWith(name.matched(1), prefix)))
				continue;
			var w = attr(t, 'frameWidth') ?? attr(t, 'width');
			var h = attr(t, 'frameHeight') ?? attr(t, 'height');
			return w != null && h != null ? [w, h] : null;
		}
		return null;
	}

	static function attr(tag:String, key:String):Null<Float> {
		var r = new EReg('\\b$key="([-\\d.]+)"', '');
		return r.match(tag) ? Std.parseFloat(r.matched(1)) : null;
	}

	static function pngSize(path:String):Null<Array<Int>> {
		if (path == null)
			return null;
		try {
			var input = sys.io.File.read(path);
			var head = input.read(24);
			input.close();
			var w = (head.get(16) << 24) | (head.get(17) << 16) | (head.get(18) << 8) | head.get(19);
			var h = (head.get(20) << 24) | (head.get(21) << 16) | (head.get(22) << 8) | head.get(23);
			return [w, h];
		} catch (e:Dynamic) {
			return null;
		}
	}
}

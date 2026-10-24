package modding.vslice;

import sys.FileSystem;

typedef ScriptEntry = {path:String, className:String, base:String};

// finds and runs V-Slice .hxc classes (stages, songs, characters) on top of the funkin.* API shims -JloorDev
class VSliceScripts {
	static var index:Map<String, ScriptEntry> = null;
	static var classes:Map<String, ScriptEntry> = null;
	static var indexedMod:String = null;

	static final CLASS_DECL = ~/class\s+(\w+)(?:\s+extends\s+([\w.]+))?/;
	static final SUPER_CALL = ~/super\s*\(\s*["']([^"']+)["']/;
	static final VARIATION = ~/variation\s*:\s*["']([^"']+)["']/;

	static function find(kind:String, id:String):Null<ScriptEntry> {
		if (indexedMod != VSlice.modRoot()) {
			indexedMod = VSlice.modRoot();
			index = new Map();
			classes = new Map();
			scan(indexedMod);
		}
		return index.get('$kind:$id');
	}

	static function kindOf(base:String):Null<String> {
		if (base == 'Stage')
			return 'stage';
		if (base == 'Song')
			return 'song';
		if (StringTools.endsWith(base, 'Character'))
			return 'character';
		return null;
	}

	static function scan(dir:String):Void {
		if (!FileSystem.exists(dir))
			return;
		for (f in FileSystem.readDirectory(dir)) {
			var path = '$dir/$f';
			if (FileSystem.isDirectory(path)) {
				scan(path);
				continue;
			}
			var inSource = path.indexOf('/source/') >= 0;
			if (!StringTools.endsWith(f, '.hxc') && !(inSource && StringTools.endsWith(f, '.hx')))
				continue;
			var src = Paths.readText(path);
			if (!CLASS_DECL.match(src))
				continue;
			var base = CLASS_DECL.matched(2) ?? '';
			classes.set(CLASS_DECL.matched(1), {path: path, className: CLASS_DECL.matched(1), base: base});
			var kind = kindOf(base);
			var rest = CLASS_DECL.matchedRight();
			if (kind == null || !SUPER_CALL.match(rest))
				continue;
			var id = SUPER_CALL.matched(1);
			if (kind == 'song' && VARIATION.match(SUPER_CALL.matchedRight().substr(0, 80)))
				id += ':' + VARIATION.matched(1);
			index.set('$kind:$id', {path: path, className: CLASS_DECL.matched(1), base: base});
		}
	}

	static function load<T>(kind:String, id:String, base:Class<Dynamic>):Null<T> {
		var entry = find(kind, id);
		if (entry == null)
			return null;

		var main = moduleOf(entry, base);
		try {
			var env = new hxscript.Environment();
			for (k => v in modding.scripting.ScriptHandler.globalEnv.variables)
				env.variables.set(k, v);
			env.addModule(main.module);
			for (dep in dependencies(main.src, entry.className))
				env.addModule(dep);
			env.start();
			var type = env.resolve(main.typeName);
			if (!(type is hxscript.types.ScriptedClass)) {
				Console.log('[V-Slice] ${entry.path} has no class ${main.typeName}', true);
				return null;
			}
			return cast(type, hxscript.types.ScriptedClass).typeCreateInstance([]);
		} catch (e:Dynamic) {
			Console.log('[V-Slice] could not build ${entry.path}: $e', true);
			return null;
		}
	}

	static function moduleOf(entry:ScriptEntry, base:Null<Class<Dynamic>>):{module:hxscript.Module, typeName:String, src:String} {
		var src = Paths.readText(entry.path);
		// hxscript only resolves type names that start uppercase (halloween-gg's class doesn't) -JloorDev
		var typeName = entry.className.charAt(0).toUpperCase() + entry.className.substr(1);
		if (typeName != entry.className)
			src = new EReg('class\\s+${entry.className}\\b', '').replace(src, 'class $typeName');
		src = prepareScript(src, base);
		return {module: new hxscript.Module(src, typeName, [], entry.path), typeName: typeName, src: src};
	}

	static function baseClassOf(base:String):Null<Class<Dynamic>> {
		return switch (base) {
			case 'Stage': funkin.play.stage.Stage;
			case 'Song': funkin.play.song.Song;
			case 'FunkinSprite': funkin.graphics.FunkinSprite;
			default: StringTools.endsWith(base, 'Character') ? funkin.play.character.BaseCharacter : null;
		};
	}

	static function dependencies(src:String, self:String):Array<hxscript.Module> {
		var modules:Array<hxscript.Module> = [];
		var seen = [self];
		var pending = [src];
		while (pending.length > 0) {
			var text = pending.pop();
			for (name => dep in classes) {
				if (seen.contains(name) || !new EReg('\\b$name\\b', '').match(text))
					continue;
				if (dep.base != '' && baseClassOf(dep.base) == null && !StringTools.startsWith(dep.base, 'Flx'))
					continue;
				seen.push(name);
				try {
					var m = moduleOf(dep, baseClassOf(dep.base));
					modules.push(m.module);
					pending.push(m.src);
				} catch (e:Dynamic) {
					Console.log('[V-Slice] could not read ${dep.path}: $e', true);
				}
			}
		}
		return modules;
	}

	public static function loadStageScript(host:game.objects.sprites.Stage, stageId:String):Null<funkin.play.stage.Stage> {
		var stage:funkin.play.stage.Stage = load('stage', stageId, funkin.play.stage.Stage);
		if (stage == null)
			return null;
		stage.host = host;
		funkin.play.PlayState.instance ??= new funkin.play.PlayState(null, game.PlayState.instance?.songFolder ?? Paths.currentSong);
		funkin.play.PlayState.instance.currentStage = stage;
		return stage;
	}

	public static function loadSongScript(songId:String):Null<funkin.play.song.Song>
		return load('song', songId, funkin.play.song.Song);

	public static function attachCharacter(host:game.objects.sprites.Character):funkin.play.character.BaseCharacter {
		var shim:funkin.play.character.BaseCharacter = load('character', host.curCharacter, funkin.play.character.MultiAnimateAtlasCharacter);
		shim ??= new funkin.play.character.BaseCharacter(host.curCharacter);
		shim.host = host;
		shim._data = FormatJson.readJson(Paths.getPath('data/characters/${host.curCharacter}', 'json'));
		funkin.play.PlayState.instance ??= new funkin.play.PlayState(null, game.PlayState.instance?.songFolder ?? core.assets.Paths.currentSong);
		return shim;
	}

	static function prepareScript(src:String, base:Null<Class<Dynamic>>):String {
		var importLine = ~/^\s*import\s+([\w.]+)(?:\s+(?:as|in)\s+(\w+))?\s*;/;
		var packageLine = ~/^\s*package\s+[\w.]*\s*;/;
		var lines = src.split('\n');
		// V-Slice's script events are global there; with unknown imports they become plain Dynamic annotations
		// the classes scripts extend too: hxscript rejects its own bridge subclass where the base type is named -JloorDev
		var dynamicTypes:Array<String> = [
			'ScriptEvent',
			'FunkinSound',
			'Stage',
			'Song',
			'BaseCharacter',
			'SparrowCharacter',
			'MultiSparrowCharacter',
			'PackerCharacter',
			'AnimateAtlasCharacter',
			'MultiAnimateAtlasCharacter',
			'FunkinSprite',
			'Bopper'
		];
		for (i in 0...lines.length) {
			// the script runs on its own, its package (rewired.stages...) means nothing here -JloorDev
			if (packageLine.match(lines[i]))
				lines[i] = '// ' + lines[i];
			if (!importLine.match(lines[i]))
				continue;
			// openfl's AssetType is an enum abstract hxscript can't import; its values are plain strings -JloorDev
			if (importLine.matched(1) == 'openfl.utils.AssetType'
				|| importLine.matched(1) == 'openfl.utils.Assets'
				|| !typeKnown(importLine.matched(1))) {
				lines[i] = '// no V-Slice API for this yet: ' + lines[i];
				dynamicTypes.push(importLine.matched(2) ?? importLine.matched(1).split('.').pop());
			}
		}

		// Polymod lets a script redefine a base hook without `override` (obliterated's onUpdate), hxscript doesn't -JloorDev
		var funcDecl = ~/^(\s*)((?:public|private|static|inline)\s+)*function\s+(\w+)/;
		var baseFields = base != null ? Type.getInstanceFields(base) : [];
		var overrideWord = ~/\boverride\s+/;
		for (i in 0...(base != null ? lines.length : 0)) {
			if (!funcDecl.match(lines[i]) && !(overrideWord.match(lines[i]) && ~/\bfunction\s+\w+/.match(lines[i])))
				continue;
			var nameMatch = ~/\bfunction\s+(\w+)/;
			if (!nameMatch.match(lines[i]))
				continue;
			var inBase = baseFields.contains(nameMatch.matched(1));
			var hasOverride = overrideWord.match(lines[i]);
			if (inBase && !hasOverride)
				lines[i] = ~/^(\s*)/.replace(lines[i], '$1override ');
			else if (!inBase && hasOverride)
				lines[i] = overrideWord.replace(lines[i], '');
		}

		src = 'import funkin.Paths; import funkin.Assets; import funkin.Preferences; ' + lines.join('\n');
		src = ~/\bnew\s+FlxSprite\s*\(/g.replace(src, 'new funkin.graphics.FunkinSprite(');
		src = ~/\bnew\s+FlxBackdrop\s*\(/g.replace(src, 'new funkin.compat.LegacyBackdrop(');
		src = ~/\bAssetType\.([A-Z_]+)/g.replace(src, '"$1"');
		// once a field holds a function hxscript won't let it be reassigned, so the `x = null` cleanup of a callback field
		// (obliterated's focus callbacks) is dropped; the callback was already unregistered and the rest of the cleanup runs -JloorDev
		var funcVar = ~/\bvar\s+(\w+)\s*:\s*\(?[\w<>?, ]*\)?\s*->[^;=]*;/;
		var rest = src;
		while (funcVar.match(rest)) {
			src = new EReg('\\b${funcVar.matched(1)}\\s*=\\s*null\\s*;', 'g').replace(src, '{}');
			rest = funcVar.matchedRight();
		}
		// Polymod lets scripts read each other's private members (a song script reading its stage's), hxscript doesn't -JloorDev
		src = ~/\bprivate\s+(var|final|function|static|inline|override)\b/g.replace(src, 'public $1');
		src = ~/(^|[^.\w])animation\.(addBySymbol|addBySymbolIndices|addByFrameLabel|addByFrameLabelIndices|addByTimeline)\b/gm.replace(src, '$1this.anim.$2');
		src = ~/\.animation\.(addBySymbol|addBySymbolIndices|addByFrameLabel|addByFrameLabelIndices|addByTimeline)\b/g.replace(src, '.anim.$1');
		src = ~/\bnew\s+FlxSpriteElement\s*\(/g.replace(src, 'new funkin.compat.SpriteElement(');
		src = ~/\bextends\s+(?:flixel\.addons\.display\.)?FlxRuntimeShader\b/g.replace(src, 'extends funkin.graphics.shaders.RuntimeShader');
		// a checked cast to a script class fails on its wired instance (ftbb's cast to FTBBStage), so it goes unchecked -JloorDev
		if (classes != null && classes.keys().hasNext()) {
			var names = [for (k in classes.keys()) k].join('|');
			src = new EReg('\\bcast\\s*\\(([^,()]+),\\s*(?:$names)\\s*\\)', 'g').replace(src, '(cast $1)');
		}
		src = new EReg(':\\s*(\\w*ScriptEvent|${dynamicTypes.join('|')})\\b', 'g').replace(src, ':Dynamic');
		return src;
	}

	static function typeKnown(path:String):Bool {
		if (Type.resolveClass(path) != null || Type.resolveEnum(path) != null)
			return true;
		try {
			return hxscript.types.TypeTools.listTypesEx(path, false, true, [hxscript.types.TypeCollection.main]) != null;
		} catch (e:Dynamic) {
			return false;
		}
	}
}

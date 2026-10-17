package modding.mods;

import core.json.engine.OptionData;
import core.enums.OptionType;
import flixel.input.keyboard.FlxKey;

class ModOptionsLoader {
	public static var modKeybindGroups:Array<{groupName:String, label:String, actions:Array<String>}> = [];

	public static function load():Map<String, Array<OptionData>> {
		var result:Map<String, Array<OptionData>> = [];

		var path = core.assets.Library.findLib('data/options.json');
		if (path == null || !sys.FileSystem.exists(path))
			return result;

		var file:ModOptionData.ModOptionsFile;
		try {
			file = FormatJson.readJson(path);
		} catch (e) {
			Console.log('[ModOptionsLoader] Error parsing options.json: $e', true);
			return result;
		}

		if (file?.categories != null) {
			for (cat in file.categories) {
				var opts:Array<OptionData> = [];

				for (entry in cat.options) {
					var entryDefault:Dynamic = Reflect.field(entry, "default");
					if (entryDefault != null && Reflect.field(SaveData.data, entry.saveField) == null)
						Reflect.setField(SaveData.data, entry.saveField, entryDefault);

					var optType:OptionType = switch (entry.type.toUpperCase()) {
						case 'NUMBER': NUMBER(entry.min ?? 0, entry.max ?? 100, entry.step ?? 1);
						default: CHECKBOX;
					};

					opts.push({
						name: entry.name,
						description: entry.description,
						saveField: entry.saveField,
						type: optType,
						displayFormat: entry.displayFormat
					});
				}

				result.set(cat.name, opts);
			}
		}

		if (file?.keybinds != null) {
			for (entry in file.keybinds) {
				var groupName = entry.groupName;
				var actions = entry.actions;
				var savedRaw:Dynamic = Reflect.field(FlxG.save.data, groupName);
				var entryDefault:Dynamic = Reflect.field(entry, "default");
				if (savedRaw == null && entryDefault != null)
					Reflect.setField(FlxG.save.data, groupName, entryDefault);

				var raw:Dynamic = Reflect.field(FlxG.save.data, groupName);
				if (raw != null) {
					var lanes:Array<Dynamic> = raw;
					var stringLanes = [
						for (lane in (lanes : Array<Dynamic>)) [for (k in (lane : Array<Dynamic>)) Std.string(k)]
					];
					Controls.instance.loadGroupPublic(groupName, stringLanes);
				}
				modKeybindGroups.push({groupName: groupName, label: entry.label, actions: actions});
			}
		}

		SaveData.flush();
		return result;
	}
}

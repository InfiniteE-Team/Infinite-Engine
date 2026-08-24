package modding.scripting;

import hxscript.Config;
import hxscript.setup.Boot;
import game.modchart.modifiers.Modifiers;

class ScriptGlobals {
	static var initialized:Bool = false;

	public static function init():Void {
		if (initialized)
			return;
		initialized = true;

		hxscript.Config.interpClass = modding.scripting.GameInterp;

		Boot.importGlobals([
			// Flixel
			'flixel.FlxG',
			'flixel.FlxSprite',
			'flixel.text.FlxText',
			'flixel.sound.FlxSound',
			'flixel.tweens.FlxTween',
			'flixel.util.FlxTimer',
			'flixel.tweens.FlxEase',
			'flixel.math.FlxMath',
			// Engine
			'core.json.engine.GlobalData.GlobalConfig',
			'game.objects.Bar',
			'game.PlayState',
			'states.MenuState',
			'utils.Alphabet',
			'game.objects.sprites.Character',
			'game.objects.sprites.Stage',
			'core.assets.Paths',
			'core.assets.FunkinSprite',
			'core.rhythm.RhythmCore',
			'modding.scripting.ScriptHandler',
			'core.config.Controls',
			'states.MusicBeatState',
			// Audio
			'core.rhythm.audio.Sound',
			'core.rhythm.audio.MasterAudio',
			'core.rhythm.audio.GameAudio',
			// Cutscenes
			'states.cutscenes.VideoState',
			'states.cutscenes.VideoSprite',
			// Scripting
			'modding.scripting.interfaces.ScriptState',
			'modding.scripting.interfaces.ScriptSubstate',
			'modding.scripting.types.ScriptClass',
			// Shaders
			'game.graphics.shaders.CustomShader',
			// Modchart
			'game.modchart.ModchartSystem',
		]);

		Config.globalVariables.set('Json', haxe.Json);
		Config.globalVariables.set('FormatJson', FormatJson);
		Config.globalVariables.set('SaveScore', core.config.SaveScore);
		Config.globalVariables.set('SaveData', core.config.SaveData);
		Config.globalVariables.set('OptionType', core.enums.OptionType);
		Config.globalVariables.set('Trace', Trace);
		Config.globalVariables.set('File', sys.io.File);
		Config.globalVariables.set('FileSystem', sys.FileSystem);
		Config.globalVariables.set('Camera', game.objects.Camera);

		// Modifiers
		Config.globalVariables.set('DrunkModifier', DrunkModifier);
		Config.globalVariables.set('TornadoModifier', TornadoModifier);
		Config.globalVariables.set('TipsyModifier', TipsyModifier);
		Config.globalVariables.set('TipsyZModifier', TipsyZModifier);
		Config.globalVariables.set('ReverseModifier', ReverseModifier);
		Config.globalVariables.set('FlipModifier', FlipModifier);
		Config.globalVariables.set('ConfusionModifier', ConfusionModifier);
		Config.globalVariables.set('MiniModifier', MiniModifier);
		Config.globalVariables.set('StealthModifier', StealthModifier);
		Config.globalVariables.set('ZModifier', ZModifier);
		Config.globalVariables.set('SpeedModifier', SpeedModifier);
		Config.globalVariables.set('ConfusionOffsetModifier', ConfusionOffsetModifier);
		Config.globalVariables.set('TwirlModifier', TwirlModifier);
		Config.globalVariables.set('ShakyModifier', ShakyModifier);
		Config.globalVariables.set('PulseModifier', PulseModifier);
		Config.globalVariables.set('BlinkModifier', BlinkModifier);
		Config.globalVariables.set('TanDrunkModifier', TanDrunkModifier);
		Config.globalVariables.set('BeatXModifier', BeatXModifier);
		Config.globalVariables.set('ShrinkXModifier', ShrinkXModifier);

		#if windows
		Config.globalVariables.set('WindowsAPI', winapi.WindowsAPI);
		Config.globalVariables.set('WindowsGDI', winapi.gdi.WindowsGDI);
		#end

		hxscript.flixel.Shims.register();
	}

	public static function initLua():Void {
		if (modding.scripting.lua.LuaScript.globalClasses != null)
			return;
		modding.scripting.lua.LuaScript.globalClasses = [
			// Flixel
			"FlxG" => flixel.FlxG,
			"FlxSprite" => flixel.FlxSprite,
			"FlxText" => flixel.text.FlxText,
			"FlxSound" => flixel.sound.FlxSound,
			"Camera" => game.objects.Camera,
			"FlxTween" => flixel.tweens.FlxTween,
			"FlxTimer" => flixel.util.FlxTimer,
			"FlxEase" => flixel.tweens.FlxEase,
			"FlxMath" => flixel.math.FlxMath,
			// Engine
			"Bar" => game.objects.Bar,
			"PlayState" => game.PlayState,
			"MenuState" => states.MenuState,
			"Alphabet" => utils.Alphabet,
			"Character" => game.objects.sprites.Character,
			"Stage" => game.objects.sprites.Stage,
			"Paths" => core.assets.Paths,
			"FunkinSprite" => core.assets.FunkinSprite,
			"RhythmCore" => core.rhythm.RhythmCore,
			// Json
			"Json" => haxe.Json,
			"FormatJson" => FormatJson,
			// Save Config Game
			"SaveScore" => core.config.SaveScore,
			"SaveData" => core.config.SaveData,
			// Sound
			"Sound" => core.rhythm.audio.Sound,
			"MasterAudio" => core.rhythm.audio.MasterAudio,
			"GameAudio" => core.rhythm.audio.GameAudio,
			// Cutscenes
			"VideoState" => states.cutscenes.VideoState,
			"VideoSprite" => states.cutscenes.VideoSprite,
			// Utils
			"Trace" => Trace,
			#if windows
			"WindowsAPI" => winapi.WindowsAPI, "WindowsGDI" => winapi.gdi.WindowsGDI, "WindowsGDIThread" => winapi.gdi.WindowsGDIThread,
			#end
			// Std
			"FileSystem" => sys.FileSystem,
			"File" => sys.io.File,
			// modchart
			"ModchartSystem" => game.modchart.ModchartSystem,
			// Shaders
			"CustomShader" => game.graphics.shaders.CustomShader,
			// modifiers
			"DrunkModifier" => DrunkModifier,
			"TornadoModifier" => TornadoModifier,
			"TipsyModifier" => TipsyModifier,
			"TipsyZModifier" => TipsyZModifier,
			"ReverseModifier" => ReverseModifier,
			"FlipModifier" => FlipModifier,
			"ConfusionModifier" => ConfusionModifier,
			"MiniModifier" => MiniModifier,
			"StealthModifier" => StealthModifier,
			"ZModifier" => ZModifier,
			"SpeedModifier" => SpeedModifier,
			"ConfusionOffsetModifier" => ConfusionOffsetModifier,
			"TwirlModifier" => TwirlModifier,
			"ShakyModifier" => ShakyModifier,
			"PulseModifier" => PulseModifier,
			"BlinkModifier" => BlinkModifier,
			"ShrinkXModifier" => ShrinkXModifier,
			"BeatXModifier" => BeatXModifier,
			"TanDrunkModifier" => TanDrunkModifier,
			// "WindowModManager" => windowmodcharting.WindowModManager
		];
	}
}

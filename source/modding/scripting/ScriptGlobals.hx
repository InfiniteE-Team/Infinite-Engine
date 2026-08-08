package modding.scripting;

import rulescript.RuleScript;

class ScriptGlobals {
	static var initialized:Bool = false;

	public static function init():Void {
		if (initialized)
			return;
		initialized = true;

		var roots = RuleScript.defaultImports[''];

		// Flixel
		roots['FlxG'] = flixel.FlxG;
		roots['FlxSprite'] = flixel.FlxSprite;
		roots['FlxText'] = flixel.text.FlxText;
		roots['FlxSound'] = flixel.sound.FlxSound;
		roots['Camera'] = game.objects.Camera;
		roots['FlxTween'] = flixel.tweens.FlxTween;
		roots['FlxTimer'] = flixel.util.FlxTimer;
		roots['FlxEase'] = flixel.tweens.FlxEase;
		roots['FlxMath'] = flixel.math.FlxMath;

		// Engine
		roots['GlobalConfig'] = core.json.engine.GlobalData.GlobalConfig;

		roots['Bar'] = game.objects.Bar;
		roots['PlayState'] = game.PlayState;
		roots['MenuState'] = states.MenuState;
		roots['Alphabet'] = utils.Alphabet;
		roots['Character'] = game.objects.sprites.Character;
		roots['Stage'] = game.objects.sprites.Stage;
		roots['Paths'] = core.assets.Paths;
		roots['FunkinSprite'] = core.assets.FunkinSprite;
		roots['RhythmCore'] = core.rhythm.RhythmCore;
		roots['ScriptHandler'] = modding.scripting.ScriptHandler;
		roots['Controls'] = core.config.Controls;

		roots['MusicBeatState'] = states.MusicBeatState;

		// Sound
		roots['Sound'] = core.rhythm.audio.Sound;
		roots['MasterAudio'] = core.rhythm.audio.MasterAudio;
		roots['GameAudio'] = core.rhythm.audio.GameAudio;

		// Cutscenes
		roots['VideoState'] = states.cutscenes.VideoState;
		roots['VideoSprite'] = states.cutscenes.VideoSprite;

		// Scripting
		roots['ScriptState'] = modding.scripting.interfaces.ScriptState;
		roots['ScriptSubstate'] = modding.scripting.interfaces.ScriptSubstate;

		roots['ScriptClass'] = modding.scripting.types.ScriptClass;

		roots['ScriptedTypeDef'] = modding.scripting.types.ScriptedTypeDef;

		// Json Formatters Engine
		roots['Json'] = haxe.Json;
		roots['FormatJson'] = FormatJson;

		// Save Content Game
		roots['SaveScore'] = core.config.SaveScore;
		roots['OptionType'] = core.enums.OptionType;
		roots['SaveData'] = core.config.SaveData;

		// Shaders
		roots['CustomShader'] = game.graphics.shaders.CustomShader;

		// Utils
		roots['Trace'] = Trace;

		#if windows
		roots['WindowsAPI'] = winapi.WindowsAPI;
		roots['WindowsGDI'] = winapi.gdi.WindowsGDI;
		roots['WindowsGDIThread'] = winapi.gdi.WindowsGDIThread;
		#end

		// Haxe std extra
		roots['FileSystem'] = sys.FileSystem;
		roots['File'] = sys.io.File;

		// modchart
		roots['ModchartSystem'] = game.modchart.ModchartSystem;
		// modifiers
		roots['DrunkModifier'] = game.modchart.modifiers.Modifiers.DrunkModifier;
		roots['TornadoModifier'] = game.modchart.modifiers.Modifiers.TornadoModifier;
		roots['TipsyModifier'] = game.modchart.modifiers.Modifiers.TipsyModifier;
		roots['TipsyZModifier'] = game.modchart.modifiers.Modifiers.TipsyZModifier;
		roots['ReverseModifier'] = game.modchart.modifiers.Modifiers.ReverseModifier;
		roots['FlipModifier'] = game.modchart.modifiers.Modifiers.FlipModifier;
		roots['ConfusionModifier'] = game.modchart.modifiers.Modifiers.ConfusionModifier;
		roots['MiniModifier'] = game.modchart.modifiers.Modifiers.MiniModifier;
		roots['StealthModifier'] = game.modchart.modifiers.Modifiers.StealthModifier;
		roots['ZModifier'] = game.modchart.modifiers.Modifiers.ZModifier;
		roots['SpeedModifier'] = game.modchart.modifiers.Modifiers.SpeedModifier;
		roots['ConfusionOffsetModifier'] = game.modchart.modifiers.Modifiers.ConfusionOffsetModifier;
		roots['TwirlModifier'] = game.modchart.modifiers.Modifiers.TwirlModifier;
		roots['ShakyModifier'] = game.modchart.modifiers.Modifiers.ShakyModifier;
		roots['PulseModifier'] = game.modchart.modifiers.Modifiers.PulseModifier;
		roots['BlinkModifier'] = game.modchart.modifiers.Modifiers.BlinkModifier;
		roots['TanDrunkModifier'] = game.modchart.modifiers.Modifiers.TanDrunkModifier;
		roots['BeatXModifier'] = game.modchart.modifiers.Modifiers.BeatXModifier;
		roots['ShrinkXModifier'] = game.modchart.modifiers.Modifiers.ShrinkXModifier;

		//roots['WindowModManager'] = windowmodcharting.WindowModManager;
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
			"DrunkModifier" => game.modchart.modifiers.Modifiers.DrunkModifier,
			"TornadoModifier" => game.modchart.modifiers.Modifiers.TornadoModifier,
			"TipsyModifier" => game.modchart.modifiers.Modifiers.TipsyModifier,
			"TipsyZModifier" => game.modchart.modifiers.Modifiers.TipsyZModifier,
			"ReverseModifier" => game.modchart.modifiers.Modifiers.ReverseModifier,
			"FlipModifier" => game.modchart.modifiers.Modifiers.FlipModifier,
			"ConfusionModifier" => game.modchart.modifiers.Modifiers.ConfusionModifier,
			"MiniModifier" => game.modchart.modifiers.Modifiers.MiniModifier,
			"StealthModifier" => game.modchart.modifiers.Modifiers.StealthModifier,
			"ZModifier" => game.modchart.modifiers.Modifiers.ZModifier,
			"SpeedModifier" => game.modchart.modifiers.Modifiers.SpeedModifier,
			"ConfusionOffsetModifier" => game.modchart.modifiers.Modifiers.ConfusionOffsetModifier,
			"TwirlModifier" => game.modchart.modifiers.Modifiers.TwirlModifier,
			"ShakyModifier" => game.modchart.modifiers.Modifiers.ShakyModifier,
			"PulseModifier" => game.modchart.modifiers.Modifiers.PulseModifier,
			"BlinkModifier" => game.modchart.modifiers.Modifiers.BlinkModifier,
			"ShrinkXModifier" => game.modchart.modifiers.Modifiers.ShrinkXModifier,
			"BeatXModifier" => game.modchart.modifiers.Modifiers.BeatXModifier,
			"TanDrunkModifier" => game.modchart.modifiers.Modifiers.TanDrunkModifier,
			//"WindowModManager" => windowmodcharting.WindowModManager
		];
	}
}

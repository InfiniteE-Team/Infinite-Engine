package core.scripting;

import rulescript.RuleScript;

class ScriptGlobals {
	static var initialized:Bool = false;

	public static function init():Void {
		if (initialized)
			return;
		initialized = true;

		var root = RuleScript.defaultImports[''];

		// Flixel
		root['FlxG'] = flixel.FlxG;
		root['FlxSprite'] = flixel.FlxSprite;
		root['FlxText'] = flixel.text.FlxText;
		root['FlxSound'] = flixel.sound.FlxSound;
		root['FlxCamera'] = flixel.FlxCamera;
		root['FlxTween'] = flixel.tweens.FlxTween;
		root['FlxTimer'] = flixel.util.FlxTimer;
		root['FlxEase'] = flixel.tweens.FlxEase;
		root['FlxMath'] = flixel.math.FlxMath;

		// Engine
		root['Bar'] = game.objects.Bar;
		root['PlayState'] = game.PlayState;
		root['MenuState'] = states.MenuState;
		root['Alphabet'] = utils.Alphabet;
		root['Character'] = game.objects.sprites.Character;
		root['Stage'] = game.objects.sprites.Stage;
		root['Paths'] = core.assets.Paths;
		root['FunkinSprite'] = core.assets.FunkinSprite;
		root['RhythmCore'] = core.rhythm.RhythmCore;
		root['ScriptHandler'] = core.scripting.ScriptHandler;

		root['ScriptedStateBase'] = core.scripting.interfaces.ScriptStateBase;
		root['ScriptSubstateBase'] = core.scripting.interfaces.ScriptSubstateBase;

		root['ScriptedState'] = core.scripting.ScriptedState;

		root['SaveData'] = core.config.SaveData;

		root['Trace'] = Trace;

		#if windows
		root['WindowsAPI'] = winapi.WindowsAPI;
		root['WindowsGDI'] = winapi.gdi.WindowsGDI;
		root['WindowsGDIThread'] = winapi.gdi.WindowsGDIThread;
		#end

		// Haxe std extra
		root['Json'] = haxe.Json;
		root['FileSystem'] = sys.FileSystem;
		root['File'] = sys.io.File;

		// modchart
		root['ModchartSystem'] = game.modchart.ModchartSystem;
		// modifiers
		root['DrunkModifier'] = game.modchart.modifiers.Modifiers.DrunkModifier;
		root['TornadoModifier'] = game.modchart.modifiers.Modifiers.TornadoModifier;
		root['TipsyModifier'] = game.modchart.modifiers.Modifiers.TipsyModifier;
		root['TipsyZModifier'] = game.modchart.modifiers.Modifiers.TipsyZModifier;
		root['ReverseModifier'] = game.modchart.modifiers.Modifiers.ReverseModifier;
		root['FlipModifier'] = game.modchart.modifiers.Modifiers.FlipModifier;
		root['ConfusionModifier'] = game.modchart.modifiers.Modifiers.ConfusionModifier;
		root['MiniModifier'] = game.modchart.modifiers.Modifiers.MiniModifier;
		root['StealthModifier'] = game.modchart.modifiers.Modifiers.StealthModifier;
		root['ZModifier'] = game.modchart.modifiers.Modifiers.ZModifier;
		root['SpeedModifier'] = game.modchart.modifiers.Modifiers.SpeedModifier;
		root['ConfusionOffsetModifier'] = game.modchart.modifiers.Modifiers.ConfusionOffsetModifier;
		root['TwirlModifier'] = game.modchart.modifiers.Modifiers.TwirlModifier;
		root['ShakyModifier'] = game.modchart.modifiers.Modifiers.ShakyModifier;
		root['PulseModifier'] = game.modchart.modifiers.Modifiers.PulseModifier;
		root['BlinkModifier'] = game.modchart.modifiers.Modifiers.BlinkModifier;
		root['TanDrunkModifier'] = game.modchart.modifiers.Modifiers.TanDrunkModifier;
		root['BeatXModifier'] = game.modchart.modifiers.Modifiers.BeatXModifier;
		root['ShrinkXModifier'] = game.modchart.modifiers.Modifiers.ShrinkXModifier;

		root['WindowModManager'] = windowmodcharting.WindowModManager;
	}

	public static function initLua():Void {
		if (core.scripting.lua.LuaScript.globalClasses != null)
			return;
		core.scripting.lua.LuaScript.globalClasses = [
			// Flixel
			"FlxG" => flixel.FlxG,
			"FlxSprite" => flixel.FlxSprite,
			"FlxText" => flixel.text.FlxText,
			"FlxSound" => flixel.sound.FlxSound,
			"FlxCamera" => flixel.FlxCamera,
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
			"SaveData" => core.config.SaveData,
			"Trace" => Trace,
			#if windows
			"WindowsAPI" => winapi.WindowsAPI, "WindowsGDI" => winapi.gdi.WindowsGDI, "WindowsGDIThread" => winapi.gdi.WindowsGDIThread,
			#end
			// Std
			"Json" => haxe.Json,
			"FileSystem" => sys.FileSystem,
			"File" => sys.io.File,
			// modchart
			"ModchartSystem" => game.modchart.ModchartSystem,
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
			"WindowModManager" => windowmodcharting.WindowModManager
		];
	}
}

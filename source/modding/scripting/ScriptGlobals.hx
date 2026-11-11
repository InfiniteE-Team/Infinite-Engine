package modding.scripting;

import hxscript.Config;
import hxscript.setup.Boot;
import game.modchart.modifiers.Modifiers;
import modding.editors.DebugMenu;

class ScriptGlobals {
	static var initialized:Bool = false;

	static var hxClassPaths:Array<String> = [
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
		'utils.Alphabet',
		'game.objects.sprites.Character',
		'game.objects.sprites.Stage',
		'core.assets.Paths',
		'core.assets.FunkinSprite',
		'core.rhythm.RhythmCore',
		'modding.scripting.ScriptHandler',
		// input
		'core.input.Controls',
		#if FORCE_TOUCH
		'core.input.TouchInput',
		#end
		'states.MusicBeatState',
		// Audio
		'core.audio.Sound',
		'core.audio.SoundFX',
		'core.audio.MasterAudio',
		'core.audio.GameAudio',
		// Cutscenes
		'states.cutscenes.VideoState',
		'game.objects.cutscenes.VideoSprite',
		// Scripting
		'modding.scripting.interfaces.ScriptState',
		'modding.scripting.interfaces.ScriptSubstate',
		'modding.scripting.types.ScriptClass',
		// Shaders
		'core.render.shaders.CustomShader',
		// Modchart
		'game.modchart.ModchartSystem',
		// Foxlite
		'foxlite.FoxBasic',
		'foxlite.FoxCache',
		'foxlite.FoxCamera',
		'foxlite.FoxInstancedModel',
		'foxlite.FoxLayer',
		'foxlite.FoxModel',
		'foxlite.FoxObject',
		'foxlite.FoxOfflineScene',
		'foxlite.FoxScene',
		'foxlite.FoxShader',
	];

	public static function init():Void {
		if (initialized)
			return;
		initialized = true;

		hxscript.Config.interpClass = modding.scripting.GameInterp;

		Boot.importGlobals(hxClassPaths);

		registerValues((k, v) -> Config.globalVariables.set(k, v));

		#if windows
		Config.globalVariables.set('WindowsAPI', winapi.WindowsAPI);
		Config.globalVariables.set('WindowsGDI', winapi.gdi.WindowsGDI);
		#end

		hxscript.setup.Shims.register();
	}

	public static function initLua():Void {
		if (modding.scripting.lua.LuaScript.globalClasses != null)
			return;

		var map:Map<String, Dynamic> = new Map<String, Dynamic>();
		registerValues((k, v) -> map.set(k, v));

		#if windows
		map.set('WindowsAPI', winapi.WindowsAPI);
		map.set('WindowsGDI', winapi.gdi.WindowsGDI);
		map.set('WindowsGDIThread', winapi.gdi.WindowsGDIThread);
		#end

		modding.scripting.lua.LuaScript.globalClasses = map;
	}

	static function registerValues(set:String->Dynamic->Void):Void {
		// Flixel
		set("FlxG", flixel.FlxG);
		set("FlxSprite", flixel.FlxSprite);
		set("FlxText", flixel.text.FlxText);
		set("FlxSound", flixel.sound.FlxSound);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxMath", flixel.math.FlxMath);
		// Engine
		set("Camera", game.objects.Camera);
		set("Bar", game.objects.Bar);
		set("PlayState", game.PlayState);
		set("Alphabet", utils.Alphabet);
		set("Character", game.objects.sprites.Character);
		set("Stage", game.objects.sprites.Stage);
		set("Paths", core.assets.Paths);
		set("FunkinSprite", core.assets.FunkinSprite);
		set("RhythmCore", core.rhythm.RhythmCore);
		set("FPSCounter", core.ui.FPSCounter);
		set("ScriptHandler", modding.scripting.ScriptHandler);
		set("Controls", Controls);
		#if FORCE_TOUCH
		set("TouchInput", TouchInput);
		#end
		set("MusicBeatState", states.MusicBeatState);
		set("StoryMenuState", states.menus.StoryMenuState);
		set("AudioAnalyzer", core.audio.AudioAnalyzer);
		// Json
		set("Json", haxe.Json);
		set("FormatJson", FormatJson);
		set("SaveScore", core.config.SaveScore);
		set("SaveData", SaveData);
		set("OptionType", core.enums.OptionType);
		// Audio
		set("Sound", core.audio.Sound);
		set("SoundFX", core.audio.SoundFX);
		set("MasterAudio", core.audio.MasterAudio);
		set("GameAudio", core.audio.GameAudio);
		// Cutscenes
		set("VideoState", states.cutscenes.VideoState);
		set("VideoSprite", game.objects.cutscenes.VideoSprite);
		// Scripting
		set("ScriptState", modding.scripting.interfaces.ScriptState);
		set("ScriptSubstate", modding.scripting.interfaces.ScriptSubstate);
		set("ScriptClass", modding.scripting.types.ScriptClass);
		// Debug / System
		set("Console", Console);
		set("FileSystem", sys.FileSystem);
		set("File", sys.io.File);
		// OpenFL
		set("Capabilities", openfl.system.Capabilities);
		// Render
		set("CustomShader", core.render.shaders.CustomShader);
		// Modchart
		set("ModchartSystem", game.modchart.ModchartSystem);
		// Config global
		set("globalConfig", core.ConfigMain.globalData);
		set("modData", modding.mods.ModData.ModConfig.modData);
		// Foxlite
		set("FoxBasic", foxlite.FoxBasic);
		set("FoxCache", foxlite.FoxCache);
		set("FoxCamera", foxlite.FoxCamera);
		set("FoxInstancedModel", foxlite.FoxInstancedModel);
		set("FoxModel", foxlite.FoxModel);
		set("FoxObject", foxlite.FoxObject);
		set("FoxOfflineScene", foxlite.FoxOfflineScene);
		set("FoxScene", foxlite.FoxScene);
		set("FoxShader", foxlite.FoxShader);
		// Modifiers
		set("DrunkModifier", DrunkModifier);
		set("TornadoModifier", TornadoModifier);
		set("TipsyModifier", TipsyModifier);
		set("TipsyZModifier", TipsyZModifier);
		set("ReverseModifier", ReverseModifier);
		set("FlipModifier", FlipModifier);
		set("ConfusionModifier", ConfusionModifier);
		set("MiniModifier", MiniModifier);
		set("StealthModifier", StealthModifier);
		set("ZModifier", ZModifier);
		set("SpeedModifier", SpeedModifier);
		set("ConfusionOffsetModifier", ConfusionOffsetModifier);
		set("TwirlModifier", TwirlModifier);
		set("ShakyModifier", ShakyModifier);
		set("PulseModifier", PulseModifier);
		set("BlinkModifier", BlinkModifier);
		set("TanDrunkModifier", TanDrunkModifier);
		set("BeatXModifier", BeatXModifier);
		set("ShrinkXModifier", ShrinkXModifier);
	}
}

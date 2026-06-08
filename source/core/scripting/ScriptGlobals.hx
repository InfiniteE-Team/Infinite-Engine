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
		root['FlxBar'] = flixel.ui.FlxBar;

		// Engine
		root['PlayState'] = game.PlayState;
		root['Character'] = game.objects.sprites.Character;
		root['Stage'] = game.objects.sprites.Stage;
		root['Paths'] = core.assets.Paths;
		root['FunkinSprite'] = core.assets.FunkinSprite;
		root['RhythmCore'] = core.rhythm.RhythmCore;
		root['ScriptHandler'] = core.scripting.ScriptHandler;
		root['ScriptedStateBase'] = core.scripting.ScriptStateBase;
		root['ScriptedState'] = core.scripting.ScriptedState;

		root['WindowsAPI'] = winapi.WindowsAPI;

		// Haxe std extra
		root['Json'] = haxe.Json;
		root['FileSystem'] = sys.FileSystem;
		root['File'] = sys.io.File;
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
			"FlxBar" => flixel.ui.FlxBar,
			// Engine
			"PlayState" => game.PlayState,
			"Character" => game.objects.sprites.Character,
			"Stage" => game.objects.sprites.Stage,
			"Paths" => core.assets.Paths,
			"FunkinSprite" => core.assets.FunkinSprite,
			"RhythmCore" => core.rhythm.RhythmCore,
			"WindowsAPI" => winapi.WindowsAPI,
			// Std
			"Json" => haxe.Json,
			"FileSystem" => sys.FileSystem,
			"File" => sys.io.File,
		];
	}
}

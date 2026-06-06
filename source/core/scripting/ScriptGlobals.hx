package core.scripting;

import rulescript.RuleScript;

class ScriptGlobals {
	static var initialized:Bool = false;

	public static function init():Void {
		if (initialized)
			return;
		initialized = true;

		// Flixel
		var flixelPkg:Map<String, Dynamic> = [
			'FlxG' => flixel.FlxG,
			'FlxSprite' => flixel.FlxSprite,
			'FlxText' => flixel.text.FlxText,
			'FlxSound' => flixel.sound.FlxSound,
			'FlxCamera' => flixel.FlxCamera,
			'FlxTween' => flixel.tweens.FlxTween,
			'FlxTimer' => flixel.util.FlxTimer,
			//'FlxColor' => flixel.util.FlxColor,
			'FlxEase' => flixel.tweens.FlxEase,
			'FlxMath' => flixel.math.FlxMath,
			'FlxBar' => flixel.ui.FlxBar,
			'LEFT_TO_RIGHT' => flixel.ui.FlxBar.FlxBarFillDirection.LEFT_TO_RIGHT,
			'RIGHT_TO_LEFT' => flixel.ui.FlxBar.FlxBarFillDirection.RIGHT_TO_LEFT,
		];

		var enginePkg:Map<String, Dynamic> = [
			'PlayState' => game.PlayState,
			'Character' => game.objects.sprites.Character,
			'Stage' => game.objects.sprites.Stage,
			'Paths' => core.assets.Paths,
			'FunkinSprite' => core.assets.FunkinSprite,
			'RhythmCore' => core.rhythm.RhythmCore,
			'ScriptHandler' => core.scripting.ScriptHandler,
			'ScriptedStateBase' => core.scripting.ScriptStateBase,
		];

		// Haxe Std
		var stdExtra:Map<String, Dynamic> = ['Json' => haxe.Json, 'FileSystem' => sys.FileSystem, 'File' => sys.io.File,];

		RuleScript.defaultImports.set('flixel', flixelPkg);
		RuleScript.defaultImports.set('engine', enginePkg);
		RuleScript.defaultImports.set('haxe', stdExtra);

		var ctx = ScriptHandler.globalContext;
		for (_ => pkg in RuleScript.defaultImports)
			for (name => val in pkg)
				ctx.types.set(name, val);

		ctx.types.set('ScriptedStateBase', ScriptStateBase);
	}
}

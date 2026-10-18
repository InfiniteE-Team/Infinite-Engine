package funkin.play.stage;

import flixel.FlxBasic;
import game.objects.sprites.Character;

// V-Slice Stage API for .hxc stage scripts: they extend this and the engine stage does the work -JloorDev
@:scriptable
@:keepSub
@:keep
class Stage {
	public var stageId:String;
	public var host:game.objects.sprites.Stage;

	public function new(id:String) {
		stageId = id;
	}

	public function buildStage():Void {}

	public function add(obj:FlxBasic):FlxBasic {
		if (host != null)
			host.addScripted(obj);
		return obj;
	}

	public function remove(obj:FlxBasic):FlxBasic {
		if (host != null)
			host.remove(obj, true);
		return obj;
	}

	public function refresh():Void {
		if (host != null)
			host.sortByZ();
	}

	public function getNamedProp(name:String):Dynamic
		return host?.getObject(name);

	public function getBoyfriend():Dynamic
		return vsliceOf(host?.getCharacterByRole('bf'));

	public function getDad():Dynamic
		return vsliceOf(host?.getCharacterByRole('dad'));

	public function getGirlfriend():Dynamic
		return vsliceOf(host?.getCharacterByRole('gf'));

	public function getPlayer():Dynamic
		return getBoyfriend();

	public function getOpponent():Dynamic
		return getDad();

	public function getCharacter(id:String):Dynamic {
		for (role in ['bf', 'dad', 'gf']) {
			var c = host?.getCharacterByRole(role);
			if (c != null && c.curCharacter == id)
				return vsliceOf(c);
		}
		return null;
	}

	static function vsliceOf(c:Character):Dynamic
		return c?.vslice != null ? c.vslice : c;

	public function addCharacter(character:Dynamic, charType:String):Void {
		var c:Character = Std.isOfType(character, funkin.play.character.BaseCharacter) ? cast(character, funkin.play.character.BaseCharacter).host : Std.downcast(character, Character);
		if (host != null && c != null)
			host.addExtraCharacter(c);
	}

	public function onCreate(e:Dynamic):Void {}

	public function onDestroy(e:Dynamic):Void {}

	public function onUpdate(e:Dynamic):Void {}

	public function update(elapsed:Float):Void {}

	public function onBeatHit(e:Dynamic):Void {}

	public function onStepHit(e:Dynamic):Void {}

	public function onCountdownStart(e:Dynamic):Void {}

	public function onCountdownStep(e:Dynamic):Void {}

	public function onCountdownEnd(e:Dynamic):Void {}

	public function onSongStart(e:Dynamic):Void {}

	public function onSongEnd(e:Dynamic):Void {}

	public function onSongRetry(e:Dynamic):Void {}

	public function onSongEvent(e:Dynamic):Void {}

	public function onSongLoaded(e:Dynamic):Void {}

	public function onNoteHit(e:Dynamic):Void {}

	public function onNoteMiss(e:Dynamic):Void {}

	public function onNoteIncoming(e:Dynamic):Void {}

	public function onNoteHoldDrop(e:Dynamic):Void {}

	public function onNoteGhostMiss(e:Dynamic):Void {}

	public function onPause(e:Dynamic):Void {}

	public function onResume(e:Dynamic):Void {}

	public function onGameOver(e:Dynamic):Void {}

	public function onStateChangeBegin(e:Dynamic):Void {}

	public function onStateChangeEnd(e:Dynamic):Void {}

	public function onSubStateOpenBegin(e:Dynamic):Void {}

	public function onSubStateOpenEnd(e:Dynamic):Void {}

	public function onSubStateCloseBegin(e:Dynamic):Void {}

	public function onSubStateCloseEnd(e:Dynamic):Void {}

	public function onFocusGained(e:Dynamic):Void {}

	public function onFocusLost(e:Dynamic):Void {}

	public function onScriptEvent(e:Dynamic):Void {}
}

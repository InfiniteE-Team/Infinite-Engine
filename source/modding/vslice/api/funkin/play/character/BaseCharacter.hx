package funkin.play.character;

import flixel.math.FlxPoint;
import game.objects.sprites.Character;

// V-Slice BaseCharacter for character scripts: wraps the engine Character, which keeps drawing and singing -JloorDev
@:scriptable
@:keepSub
@:keep
class BaseCharacter {
	public var characterId:String;
	public var host:Character;

	public var idleSuffix:String = '';
	public var shouldAlternate:Null<Bool> = null;
	public var hasDanced:Bool = false;
	public var holdTimer:Float = 0;
	public var danceEvery:Float = 1;
	public var ignoreExclusionPref:Array<String> = [];
	public var _data:Dynamic = null;
	public var debug:Bool = false;
	public var canPlayOtherAnims:Bool = true;
	public var originalPosition(get, never):FlxPoint;

	function get_originalPosition():FlxPoint
		return FlxPoint.weak(host?.x ?? 0, host?.y ?? 0);

	public function resetCameraFocusPoint():Void {}

	public function new(id:String) {
		characterId = id;
	}

	public var x(get, set):Float;
	public var y(get, set):Float;
	public var alpha(get, set):Float;
	public var visible(get, set):Bool;
	public var flipX(get, set):Bool;
	public var zIndex(get, set):Int;
	public var shader(get, set):Dynamic;
	public var color(get, set):Int;
	public var scale(get, never):FlxPoint;
	public var animation(get, never):Dynamic;
	public var anim(get, never):Dynamic;
	public var library(get, never):Dynamic;
	public var cameraFocusPoint(get, never):FlxPoint;
	public var width(get, never):Float;
	public var height(get, never):Float;

	function body()
		return host?.layers[0];

	function get_x():Float
		return host?.x ?? 0;

	function set_x(v:Float):Float {
		if (host != null)
			host.x = v;
		return v;
	}

	function get_y():Float
		return host?.y ?? 0;

	function set_y(v:Float):Float {
		if (host != null)
			host.y = v;
		return v;
	}

	function get_alpha():Float
		return body()?.alpha ?? 1;

	function set_alpha(v:Float):Float {
		if (host != null)
			for (l in host.layers)
				l.alpha = v;
		return v;
	}

	function get_visible():Bool
		return body()?.visible ?? false;

	function set_visible(v:Bool):Bool {
		if (host != null)
			for (l in host.layers)
				l.visible = v;
		return v;
	}

	function get_flipX():Bool
		return body()?.flipX ?? false;

	function set_flipX(v:Bool):Bool {
		if (host != null)
			for (l in host.layers)
				l.flipX = v;
		return v;
	}

	function get_zIndex():Int
		return host?.zIndex ?? 0;

	function set_zIndex(v:Int):Int {
		if (host != null)
			host.zIndex = v;
		return v;
	}

	function get_shader():Dynamic
		return body()?.shader;

	function set_shader(v:Dynamic):Dynamic {
		if (host != null)
			for (l in host.layers)
				l.shader = v;
		return v;
	}

	function get_color():Int
		return body()?.color ?? 0xFFFFFFFF;

	function set_color(v:Int):Int {
		if (host != null)
			for (l in host.layers)
				l.color = v;
		return v;
	}

	function get_scale():FlxPoint
		return body()?.scale;

	function get_animation():Dynamic
		return body()?.animation;

	function get_anim():Dynamic
		return body()?.anim;

	function get_library():Dynamic
		return body()?.library;

	function get_cameraFocusPoint():FlxPoint
		return host?.cameraFocusPoint;

	function get_width():Float
		return body()?.width ?? 0;

	function get_height():Float
		return body()?.height ?? 0;

	public function setPosition(x:Float = 0, y:Float = 0):Void
		host?.setPosition(x, y);

	public function getMidpoint(?point:FlxPoint):FlxPoint
		return body() != null ? body().getMidpoint(point) : FlxPoint.get();

	public function getGraphicMidpoint(?point:FlxPoint):FlxPoint
		return body() != null ? body().getGraphicMidpoint(point) : FlxPoint.get();

	public function getCurrentAnimation():String
		return body()?.currentAnim ?? '';

	public function hasAnimation(name:String):Bool
		return host?.existsAnim(name) == true;

	public function isAnimationFinished():Bool
		return body() != null && body().isFinished(body().currentAnim);

	public function getFramesWithKeyword(keyword:String):Array<animate.internal.Frame> {
		var result:Array<animate.internal.Frame> = [];
		if (host != null)
			for (l in host.layers)
				if (l.isAnimate)
					result = result.concat(funkin.graphics.FunkinSprite.framesWithKeyword(l.library, keyword));
		return result;
	}

	public function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reversed:Bool = false):Void
		host?.playAnimRaw(name, restart);

	public function playSingAnimation(dir:Int, miss:Bool = false, ?suffix:String = ''):Void {
		var name = Character.getCharAnim(dir) + (miss ? 'miss' : '');
		if (suffix != null && suffix != '' && hasAnimation('$name-$suffix'))
			name = '$name-$suffix';
		playAnimation(name, true);
	}

	public function dance(forceRestart:Bool = false):Void {
		if (shouldAlternate == null)
			shouldAlternate = hasAnimation('danceLeft$idleSuffix') || hasAnimation('danceLeft');
		if (shouldAlternate) {
			var side = hasDanced ? 'danceRight' : 'danceLeft';
			playAnimation(hasAnimation('$side$idleSuffix') ? '$side$idleSuffix' : side, true);
			hasDanced = !hasDanced;
		} else
			playAnimation(hasAnimation('idle$idleSuffix') ? 'idle$idleSuffix' : 'idle', forceRestart);
	}

	public function resetCharacter(resetCamera:Bool = true):Void {}

	public function onAnimationFinished(name:String):Void {}

	public function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int):Void {}

	public function onCreate(e:Dynamic):Void {}

	public function onDestroy(e:Dynamic):Void {}

	public function onUpdate(e:Dynamic):Void {}

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

	public function onFocusGained(e:Dynamic):Void {}

	public function onFocusLost(e:Dynamic):Void {}

	public function onScriptEvent(e:Dynamic):Void {}
}

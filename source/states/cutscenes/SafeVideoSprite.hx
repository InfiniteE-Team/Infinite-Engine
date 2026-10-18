package states.cutscenes;

#if VIDEO_ALLOWED
// hxvlc's video sprite made safe to stop and destroy at any time; every video sprite in the engine builds on it -JloorDev
class SafeVideoSprite extends hxvlc.flixel.FlxVideoSprite {
	// libvlc deadlocks when a video that was played but never got its format (play() then pause() right away, like
	// obliterated's cutscene) is stopped or released: its video thread wakes up inside the format setup wanting the
	// player lock stop is holding. So until the format arrives, stop/destroy only mute and hide it and finish after. -JloorDev
	var played:Bool = false;
	var formatReady:Bool = false;
	var pendingStop:Bool = false;
	var pendingDestroy:Bool = false;

	// destroyed by a script but still waiting on VLC; kept here so nothing collects them meanwhile -JloorDev
	static var parked:Array<SafeVideoSprite> = [];

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y);
		antialiasing = SaveData.data.antialiasing;
		bitmap.onFormatSetup.add(onFormatReady);
	}

	override public function play():Bool {
		played = true;
		return super.play();
	}

	override public function stop():Void {
		if (waitingOnVlc()) {
			pendingStop = true;
			hush();
			return;
		}
		super.stop();
	}

	override public function destroy():Void {
		if (waitingOnVlc()) {
			pendingDestroy = true;
			hush();
			kill();
			if (!parked.contains(this))
				parked.push(this);
			return;
		}
		super.destroy();
	}

	inline function waitingOnVlc():Bool
		return played && !formatReady && bitmap != null;

	// muted and hidden, and running so VLC can finish setting up the format -JloorDev
	function hush():Void {
		visible = false;
		bitmap.volume = 0;
		bitmap.resume();
	}

	// this fires with hxvlc's texture lock held, the real stop goes on the next frame -JloorDev
	function onFormatReady():Void {
		formatReady = true;
		if (pendingStop || pendingDestroy)
			haxe.Timer.delay(finishPending, 0);
	}

	function finishPending():Void {
		if (pendingDestroy) {
			pendingDestroy = false;
			pendingStop = false;
			parked.remove(this);
			super.stop();
			super.destroy();
		} else if (pendingStop) {
			pendingStop = false;
			super.stop();
		}
	}
}
#end

package modding.vslice;

// V-Slice sends every script event to the stage, the characters and the song; this does the same for the scripted ones -JloorDev
class VSliceHooks {
	static var receivers:Array<Dynamic> = [];
	static var broken:haxe.ds.ObjectMap<Dynamic, Array<String>> = new haxe.ds.ObjectMap();

	static final PER_FRAME = ['update', 'onUpdate', 'onStepHit', 'onBeatHit', 'onAnimationFrame'];

	public static var failures:Int = 0;

	public static function reset():Void {
		receivers = [];
		broken = new haxe.ds.ObjectMap();
		failures = 0;
		funkin.Conductor.stepHit.removeAll();
		funkin.Conductor.beatHit.removeAll();
	}

	public static function register(receiver:Dynamic):Void {
		if (receiver != null && !receivers.contains(receiver))
			receivers.push(receiver);
	}

	public static function unregister(receiver:Dynamic):Void
		receivers.remove(receiver);

	public static var active(get, never):Bool;

	static function get_active():Bool
		return receivers.length > 0;

	public static function dispatch(hook:String, event:Dynamic):Void {
		if (receivers.length == 0)
			return;
		for (r in receivers.copy())
			call(r, hook, event);
	}

	public static function call(receiver:Dynamic, hook:String, event:Dynamic):Void {
		if (broken.get(receiver)?.contains(hook) == true)
			return;
		var fn = Reflect.field(receiver, hook);
		if (fn == null || !Reflect.isFunction(fn))
			return;
		var ps = funkin.play.PlayState.instance;
		var hud = ps?.camHUD;
		var hudVisible = hud?.visible ?? true;
		var hudAlpha = hud?.alpha ?? 1.0;
		var inCutscene = ps?.isInCutscene ?? false;
		try {
			Reflect.callMethod(receiver, fn, [event]);
		} catch (err:Dynamic) {
			failures++;
			if (!PER_FRAME.contains(hook) && hook != 'onDestroy' && ps != null) {
				try {
					if (hud != null && hud.exists) {
						hud.visible = hudVisible;
						hud.alpha = hudAlpha;
					}
					ps.isInCutscene = inCutscene;
					if (event != null && Reflect.hasField(event, 'eventCanceled'))
						event.eventCanceled = false;
				} catch (_:Dynamic) {}
			}
			if (PER_FRAME.contains(hook)) {
				if (!broken.exists(receiver))
					broken.set(receiver, []);
				broken.get(receiver).push(hook);
				Console.log('[V-Slice] ${nameOf(receiver)}.$hook failed, skipping it from now on: $err', true);
			} else
				Console.log('[V-Slice] ${nameOf(receiver)}.$hook failed: $err', true);
		}
	}

	static function nameOf(receiver:Dynamic):String {
		var id:String = Reflect.getProperty(receiver, 'stageId') ?? Reflect.getProperty(receiver, 'characterId') ?? Reflect.getProperty(receiver, 'id');
		return id ?? Type.getClassName(Type.getClass(receiver));
	}

	public static function event(type:String, ?fields:Dynamic):Dynamic {
		var e:Dynamic = fields ?? {};
		e.type = type;
		e.eventCanceled = false;
		e.cancelable = false;
		e.cancel = () -> e.eventCanceled = true;
		e.cancelEvent = () -> e.eventCanceled = true;
		e.stopPropagation = () -> {};
		return e;
	}

	public static function songEvent(e:core.json.song.SongData.EventsData):Void {
		if (receivers.length == 0)
			return;
		var args:Dynamic = e.arguments;
		var kind:String = args?.vsKind ?? e.name;
		var value:Dynamic = args?.vsValue ?? args;
		dispatch('onSongEvent', event('SONG_EVENT', {eventData: {eventKind: kind, value: value, time: e.time}}));
	}

	public static function noteEvent(type:String, note:game.objects.sprites.notes.Note, ?judgement:String):Dynamic {
		var dir = note?.direction ?? 0;
		var data:Dynamic = {
			time: note?.strumTime ?? 0.0,
			data: dir,
			length: 0.0,
			kind: note?.noteType,
			getDirection: () -> dir % 4,
			getMustHitNote: () -> note?.mustPress == true
		};
		return event(type, {
			note: {
				kind: note?.noteType,
				noteData: data,
				direction: dir % 4,
				mustPress: note?.mustPress == true
			},
			judgement: judgement,
			isComboBreak: false,
			healthChange: 0.0,
			score: 0
		});
	}
}

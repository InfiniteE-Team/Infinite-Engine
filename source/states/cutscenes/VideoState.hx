package states.cutscenes;

#if VIDEO_ALLOWED
import hxvlc.util.Handle;
import hxvlc.flixel.FlxVideo;

class VideoState extends FlxVideo {
	public var finishCallback:Void->Void;
	public var errorCallback:String->Void;
	public var loadCallback:Void->Void;

	public var isLoaded:Bool = false;

	override public function new(path:String, ?loop:Bool = false, ?smoothing:Bool = true, ?loadCallback:Void->Void, ?finishCallback:Void->Void,
			?errorCallback:String->Void) {
		super(smoothing);
		this.loadCallback = loadCallback;
		this.finishCallback = finishCallback;
		this.errorCallback = errorCallback;

		init(path, loop);
	}

	function init(path:String, loop:Bool) {
		Handle.initAsync(function(success:Bool):Void {
			if (!success)
				return;

			onEncounteredError.add(function(message:String) {
				Trace.traceOnce('VLC not load: $message', true);

				if (errorCallback != null)
					errorCallback(message);
			});

			onEndReached.add(function() {
				if (finishCallback != null)
					finishCallback();
			});

			onFormatSetup.add(function():Void {
				isLoaded = true;

				if (loadCallback != null)
					loadCallback();
			});

			try {
				if (load(path, loop ? ['input-repeat=65545'] : null)) {
					play();
				}
			} catch (e:Dynamic) {
				Trace.traceOnce('VLC not load!: $e', true);
			}
		});
	}
}
#end

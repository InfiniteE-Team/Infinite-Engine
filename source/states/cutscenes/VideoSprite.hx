package states.cutscenes;

#if VIDEO_ALLOWED
import hxvlc.util.Handle;
import hxvlc.flixel.FlxVideoSprite;

class VideoSprite extends FlxVideoSprite {
	public var finishCallback:Void->Void;
	public var errorCallback:String->Void;
	public var loadCallback:Void->Void;

	public var isLoaded:Bool = false;

	override public function new(?x:Float = 0, ?y:Float = 0, path:String, loop:Bool = false, ?loadCallback:Void->Void, ?finishCallback:Void->Void,
			?errorCallback:String->Void) {
		super(x, y);

		this.loadCallback = loadCallback;
		this.finishCallback = finishCallback;
		this.errorCallback = errorCallback;
		init(path, loop);
	}

	function init(path:String, loop:Bool) {
		Handle.initAsync(function(success:Bool):Void { 
            if (!success)
                return;

            antialiasing = SaveData.data.antialiasing; 

            bitmap.onEncounteredError.add(function(message:String) {
                Trace.traceOnce('VLC not load: $message', true);

                if (errorCallback != null)
                    errorCallback(message);
            });

            bitmap.onEndReached.add(function() {
                if (finishCallback != null)
                    finishCallback();
            });

            bitmap.onFormatSetup.add(function():Void {
                if (bitmap != null && bitmap.bitmapData != null) {
                    final scale:Float = Math.min(FlxG.width / bitmap.bitmapData.width, FlxG.height / bitmap.bitmapData.height);

                    setGraphicSize(bitmap.bitmapData.width * scale, bitmap.bitmapData.height * scale);
                    updateHitbox();

                    isLoaded = true;

                    if (loadCallback != null)
                        loadCallback();
                }
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

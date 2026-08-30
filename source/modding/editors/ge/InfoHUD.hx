package modding.editors.ge;
import flixel.util.FlxColor;

class InfoHUD extends flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxBasic> {
    var infoText:flixel.text.FlxText;

	public function new() {
        super();
        createHUD();
    }

	public function createHUD() {
		infoText = new flixel.text.FlxText(FlxG.width * 0.7, 8, 0, "", 16);
		infoText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE);
		infoText.borderColor = FlxColor.BLACK;
		infoText.scrollFactor.set(0, 0);
		add(infoText);
	}

	public function updateInfoText(songPosition:Float, stepInMs:Float, bpm:Float) {
		var seconds:Float = songPosition / 1000.0;
		var step:Int = Std.int(songPosition / stepInMs);
		var beat:Int = step >> 2;

		infoText.text = 'Time: ${flixel.util.FlxStringUtil.formatTime(seconds, true)}'
			+ '\nStep: $step'
			+ '\nBeat: $beat'
			+ '\nBPM: ${bpm}';
	}
}

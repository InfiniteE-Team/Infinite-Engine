package modding.editors.ui;

import flixel.text.FlxText;
import flixel.util.FlxColor;

// "Label: [ ]", click to toggle -JloorDev
class CheckBox extends FlxText {
	public var checked(default, null):Bool = false;

	var title:String;
	var cam:flixel.FlxCamera;
	var onToggle:Bool->Void;

	public function new(x:Float, y:Float, title:String, checked:Bool, ?cam:flixel.FlxCamera, ?onToggle:Bool->Void) {
		super(x, y, 0, '');
		this.title = title;
		this.cam = cam;
		this.onToggle = onToggle;
		setFormat(Paths.getPath('Funkin.otf', 'font'), 14, FlxColor.WHITE, 'left');
		setChecked(checked);
	}

	public function setChecked(v:Bool):Void {
		checked = v;
		text = '$title: [${v ? 'x' : ' '}]';
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var over = overlapsPoint(FlxG.mouse.getViewPosition(cam != null ? cam : FlxG.camera), true, cam);
		color = over ? FlxColor.YELLOW : FlxColor.WHITE;
		if (over && FlxG.mouse.justPressed) {
			setChecked(!checked);
			if (onToggle != null)
				onToggle(checked);
		}
	}
}

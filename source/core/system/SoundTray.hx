package core.system;

import flixel.system.ui.FlxSoundTray;
import flash.display.Bitmap;
import flash.display.BitmapData;
import openfl.utils.Assets;

class SoundTray extends FlxSoundTray {
	var bg:Bitmap = null;
	private var blocks:Array<Bitmap> = [];
	private var volumeMaxSound:String;

	public function new() {
		super();

		scaleX = 0.7;
		scaleY = 0.7;

		volumeMaxSound = Paths.getPath("soundtray/VolMAX", 'sound');

		while (this.numChildren > 0) {
			this.removeChildAt(0);
		}

		var bgPath:String = Paths.getPath("soundtray/volumebox", 'image');

		if (bgPath != null) {
			var bmd:BitmapData = openfl.Assets.getBitmapData(bgPath);
			if (bmd != null) {
				bg = new Bitmap(bmd);
				addChild(bg);
			}
		}

		for (i in 1...11) {
			var blockPath:String = Paths.getPath("soundtray/bars_" + i, 'image');
			var bitmapData:BitmapData = blockPath != null ? BitmapData.fromFile(blockPath) : null;
			if (bitmapData != null) {
				var tmp:Bitmap = new Bitmap(bitmapData);
				tmp.x = 23;
				tmp.y = 15;
				tmp.visible = false;
				addChild(tmp);
				blocks.push(tmp);
			}
		}

		y = (-height + 10);
		visible = false;
	}

	override public function showAnim(volume:Float, ?sound:Dynamic, duration:Float = 1.0, label:String = "VOLUME"):Void {
		_timer = duration;
		y = 10;
		visible = true;
		active = true;

		screenCenter();

		var oldVolume:Float = FlxG.sound.volume;
		var up:Bool = (volume > oldVolume);

		if (up) {
			if (oldVolume >= 1.0 && volumeMaxSound != null)
				FlxG.sound.play(openfl.Assets.getSound(volumeMaxSound));
			else {
				var snd = Paths.getPath("soundtray/Volup", 'sound');
				if (snd != null)
					FlxG.sound.play(openfl.Assets.getSound(snd));
			}
		} else {
			var snd = Paths.getPath("soundtray/Voldown", 'sound');
			if (snd != null && volume > 0)
				FlxG.sound.play(openfl.Assets.getSound(snd));
		}

		updateBars(volume);
	}

	override public function screenCenter():Void {
		x = (openfl.Lib.current.stage.stageWidth - width) / 2;
	}

	private function updateBars(volume:Float):Void {
		var globalVolume:Int = Math.round(volume * 10);
		for (b in blocks)
			b.visible = false;
		if (globalVolume > 0 && globalVolume <= blocks.length)
			blocks[globalVolume - 1].visible = true;
	}
}

package core.json.extensions;

typedef AudioData = {
	var path:String;
	var ?volume:Float; // 0.0 – 1.0
	var ?bpm:Float;
	var ?looped:Bool;
	var ?fadeIn:Float;
	var ?fadeOut:Float;
	var ?startTime:Float;
	var ?event:String; // "start" | "hover" | "click" | "destroy"
	var ?pitch:Float;
	var ?channel:String; // "music" | "sfx" | "voice" | "ambient"
}

package core.json.extensions;

typedef TweenData = {
	var type:String; // "fadeIn" | "fadeOut" | "slideUp" | "slideDown"
	// "slideLeft" | "slideRight" | "scale" | "bounce"
	var duration:Float; // segundos
	var ?delay:Float; // segundos antes de ejecutar
	var ?ease:String; // "linear" | "easeIn" | "easeOut" | "easeInOut"
	// "easeOutBack" | "elasticOut" | "bounceOut"
}

typedef LoopAnimData = {
	var type:String; // "frameLoop" | "floatY" | "floatX" | "pulse"
	// "rotate" | "colorCycle"
	var duration:Float;
	var ?pingPong:Bool;
}

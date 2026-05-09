package core.json.objects;

typedef NoteSkinData = {
	var props:SpriteData.ObjectData;
	var ?author:String;
	var ?description:String;

    var ?frameScale:Int;

	// shader RGB

	var ?colorAuto:Bool;

	var ?colorMult:Float;

	var ?colorDirections:Array<{r:Array<Float>, g:Array<Float>, b:Array<Float>}>;

	var ?colorPalette:Array<{r:String, g:String, b:String}>;

	var ?noStaticRGB:Bool;

	var ?colorHSV:Array<{h:Float, s:Float, b:Float}>;
}

/*
	Example:
	"colorDirections": [
		{
			"r":[0.76,0.11,0.67],
			"g":[0,0,0], 
			"b":[0.09,0.03,0.94]
		},
		{
			"r":[0,1,1],
			"g":[0,0,0],
			"b":[0,1,0]
		},
		{
			"r":[0.07,0.98,0.02],
			"g":[0,0,0],
			"b":[0,0.96,0]
		},
		{ 
			"r":[0.98,0.22,0.25],
			"g":[0,0,0],
			"b":[0.96,0.09,0.12]
		}
	]
 */

package core.json.objects;
import core.json.extensions.SpriteData;

typedef NoteSkinData = {
	var props:ObjectData;
	var ?author:String;
	var ?description:String;

	// shader RGB
	var ?colorAuto:Bool;
	var ?colorPalette:Array<{r:Array<Float>, g:Array<Float>, b:Array<Float>}>;
	var ?noStaticRGB:Bool;
	var ?colorHSV:Array<{h:Float, s:Float, b:Float}>;
}

/*
	Example:
	"colorPalette": [
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

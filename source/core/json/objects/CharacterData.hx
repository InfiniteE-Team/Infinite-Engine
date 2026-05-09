package core.json.objects;

typedef CharacterData = {
	var meta:MetaData;
	var gameplay:GameplayData;
	var render:RenderData;
	var icon:IconData;
}

// meta for chars
typedef MetaData = {
    var ?isPlayer:Bool;
}

// gameplay for chars
typedef GameplayData = {
    var position:Array<Float>;
    var cameraOffset:Array<Float>;
    var ?death:CharDeath;

    var ?idleAfterSing:Bool;
}

typedef CharDeath = {
	var character:String;
	var sound:String;
	var endAnim:String;
}

// render for chars
typedef RenderData = {
    var layers:Array<SpriteData.ObjectData>;
}

// icons for chars
typedef IconData = {
    var path:String;
    var ?flipX:Bool;
    var ?flipY:Bool;

    var ?bumpInBeats:Bool;
    var ?stepTempo:Float;

    var anims:Array<SpriteData.AnimData>;
}

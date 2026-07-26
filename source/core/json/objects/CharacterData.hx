package core.json.objects;
import core.json.extensions.SpriteData;

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
    var ?singTime:Float;
}

typedef CharDeath = {
	var character:String;
	var sound:String;
	var music:String;
	var endSound:String;
}

// render for chars
typedef RenderData = {
    var layers:Array<ObjectData>;
}

// icons for chars
typedef IconData = {
    var ?props:ObjectData;
    var ?bumpInBeats:Bool;
    var ?stepTempo:Float;
}

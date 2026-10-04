package core.json.objects;

import core.json.extensions.SpriteData.ObjectData;
import core.json.objects.NoteSkinData;

typedef NoteTypeData = {
    var ?meta:NoteTypeMeta;
    var ?gameplay:NoteTypeGameplay;
    var ?visual:NoteTypeVisual;
}

typedef NoteTypeMeta = {
    var ?name:String;
    var ?description:String;
    var ?author:String;
}

typedef NoteTypeGameplay = {
    var ?damage:Bool;
    var ?damageOnHit:Float;
    var ?damageOnMiss:Float;

    // health
    var ?healthGain:Float;
    var ?healthLoss:Float;
    var ?noHealthGain:Bool;
    var ?noHealthLoss:Bool;

    var ?drain:Bool;
    var ?drainRate:Float;

    var ?poison:Bool;
    var ?poisonDuration:Float;
    var ?poisonRate:Float;

    // score
    var ?noScore:Bool;
    var ?scoreMult:Float;

    var ?noMiss:Bool;
    var ?autoHit:Bool;
    var ?ignoreNote:Bool;
    var ?hitsound:String;
}

typedef NoteTypeVisual = {
    var ?noteSkin:NoteSkinData;
    var ?colorPalette:haxe.DynamicAccess<Array<String>>;
}
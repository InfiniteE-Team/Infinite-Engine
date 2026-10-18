package core.json.objects;

import core.json.extensions.AudioData;
import core.json.extensions.SpriteData.ObjectData;

typedef CountdownData = {
    var countdown:Array<Countdown>;
    var ?soundFolder:String;
}

typedef Countdown = {
    var ?props:ObjectData;
    var ?sound:AudioData;
}
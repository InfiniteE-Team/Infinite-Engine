package game;
import game.objects.sprites.Character;
class PlayState extends MusicBeatState {
    public static var instance:PlayState;
    
    override public function create() {
        instance = this;

        var charList = [
            { id: "bf", name: "bf"}/*,
            { id: "dad", name: "dad"},
            { id: "gf",  name: "gf"}*/ 
        ];

        super.create();

        for (data in charList) {
            Character.spawn(data.id, data.name);
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.W)
            Character.fetch('bf').playAnim('singUP',true);
            
    }

    override public function beatHit()
    {
        super.beatHit();

        for (id in ['bf']) {
            var char = Character.fetch(id);
            if (char != null) char.dance();
        }
    }
}
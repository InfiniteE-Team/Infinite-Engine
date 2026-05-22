package game.objects;

class Countdown
{
    var count:Int = 0;
    // the countdown for playstate
    public function new()
    {

    }

    function onCountdown()
    {
        
        count++;
    }
}
package game.objects.sprites.notes;
import core.assets.FunkinSprite;
class Note extends FunkinSprite
{
  public var isSustain:Bool = false;
  public var noteType:String = 'normal';
  
  public function new(x:Float,y:Float,isSustain:Bool)
  {
    super(x,y);

    setPosition(x,y);

    this.isSustain = isSustain;
    noteLoad();
  }

  public function noteLoad() {
    frames = Paths.getPath( , );
    for (anim in )
         animation.addbyPrefix();
    
  }

  public function config() {
    if (isSustain) {

    }
    else {

    }
  }
  
}

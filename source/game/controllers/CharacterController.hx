package game.controllers;
import game.PlayState;
import game.objects.sprites.Character;
import core.assets.FunkinSprite;
import core.assets.FunkinObjectRegistry;
import core.config.Controls;

class CharacterController extends FunkinObjectRegistry
{
	var chars:Character;
	var control:Controls;

    public function new(id:String, ?curCharacter:String = 'bf', ?x:Float = 0, ?y:Float = 0)
    {
		super(id,x,y);
		control = new Controls();
    }

    public function loadCharacter(id:String,name:String):FunkinSprite {
        if (existsId(id)) {
			return get(id);
		}
		chars = new Character(id, name);
		registry.set(id, chars);
		for (layer in chars.layers)
			PlayState.instance.add(layer);
		PlayState.instance.add(chars);

		return chars;
	}

	public function isSinging()
	{
		for (data in PlayState.SONG.chars){
			var char = cast(get(data.id), Character);
        	if (char == null) continue;
			for (i in 0...control.inputNotes.length){
				if (control.getInputNotes()[i]){
					char.playAnim('sing'+char.notesAnim[i], true);
					char.isSing = true;
				}
			}
		}
	}

	public function removeChar(id:String):Void {
		if (!existsId(id))
			return;

		chars = cast(get(id), Character);
		for (layer in chars.layers) {
			PlayState.instance.remove(layer);
			layer.destroy();
		}
		PlayState.instance.remove(chars);
		chars.destroy();
		registry.remove(id);
	}
}
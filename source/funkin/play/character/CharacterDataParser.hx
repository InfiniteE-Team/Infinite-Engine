package funkin.play.character;

import game.objects.sprites.Character;

// V-Slice CharacterDataParser for stage scripts: builds an engine character by id -JloorDev
@:keep
class CharacterDataParser {
	public static function fetchCharacter(id:String):Dynamic {
		var c = new Character('vslice-$id', id);
		return c.vslice != null ? c.vslice : c;
	}
}

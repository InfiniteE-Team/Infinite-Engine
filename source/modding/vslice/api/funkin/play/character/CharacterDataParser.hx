package funkin.play.character;

import game.objects.sprites.Character;

// V-Slice CharacterDataParser for stage scripts: builds an engine character by id -JloorDev
@:keep
class CharacterDataParser {
	public static function fetchCharacter(id:String):Dynamic
		return BaseCharacter.wrap(new Character('vslice-$id', id));
}

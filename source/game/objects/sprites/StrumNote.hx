package game.objects.sprites;

import utils.UtilsData;
import core.assets.FunkinObjectRegistry;
import core.json.objects.NoteSkinData;

class StrumNote extends FunkinObjectRegistry {
	public var noteSkinData:NoteSkinData;
    public var noteskin:String = 'default';

	public function new(id:String, x:Float, y:Float) {
		super(id, x, y);
        strumLoad(x,y);
	}

	public function strumLoad(x:Float,y:Float) {
		var noteDataPath:String = 'noteskins/$noteskin/skin';
		noteSkinData = UtilsData.readJson(Paths.getPath('data/$noteDataPath', "json"));

		frames = Paths.getPath(noteDataPath, "animated");
		loadProps(noteSkinData.props, 'noteskins/$noteskin');
	}
/*
    public static function spawn(id:String, x:Float = 0, y:Float = 0):StrumNote {
		if (FunkinObjectRegistry.existsId(id)) {
			// strum exists yep
			return cast fetch(id);
		}

		var strumnote = new StrumNote(id, x, y);
		PlayState.instance.add(strumnote);
		return strumnote;
	}

    public static function fetch(id:String):StrumNote {
		return cast FunkinObjectRegistry.get(id);
	}

	public static function removeStrums(id:String):Void {
		var strumnote = fetch(id);
		if (strumnote == null)
			return;

		PlayState.instance.remove(strumnote);
		strumnote.destroy();
	}*/
}

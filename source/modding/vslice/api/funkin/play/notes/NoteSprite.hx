package funkin.play.notes;

// for scripts that draw and judge their own notes -JloorDev
@:keep
class NoteSprite extends funkin.graphics.FunkinSprite {
	public var noteData:Dynamic;
	public var direction:Int;
	public var noteStyle:Dynamic;
	public var hasBeenHit:Bool = false;
	public var mayHit:Bool = false;
	public var hasMissed:Bool = false;
	public var handledMiss:Bool = false;
	public var tooEarly:Bool = true;
	public var lowPriority:Bool = false;
	public var scoreable:Bool = true;
	public var isHoldNote:Bool = false;
	public var holdNoteSprite:Dynamic = null;

	public function new(?noteStyle:Dynamic, direction:Int = 0) {
		super();
		this.noteStyle = noteStyle;
		this.direction = direction;
	}
}

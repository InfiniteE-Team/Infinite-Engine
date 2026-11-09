package funkin.play.notes.notestyle;

@:keep
class NoteStyle {
	public var id:String;

	public function new(id:String)
		this.id = id;

	public function getSplashOffsets():Array<Float>
		return [0, 0];

	public function getHoldCoverOffsets():Array<Float>
		return [0, 0];

	public function isHoldNoteCoverEnabled():Bool
		return false;
}

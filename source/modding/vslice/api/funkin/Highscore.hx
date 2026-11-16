package funkin;

class Highscore {
	public static var tallies:Tallies = new Tallies();
}

@:forward
abstract Tallies(RawTallies) {
	public function new() {
		this = {
			combo: game.PlayStateConfig.combo,
			missed: game.PlayStateConfig.misses,
			shit: 0,
			bad: 0,
			good: 0,
			sick: 0,
			totalNotes: game.PlayStateConfig.totalNotes,
			totalNotesHit: game.PlayStateConfig.hitNotes,
			maxCombo: 0,
			score: game.PlayStateConfig.score,
			isNewHighscore: false
		}
	}
}

typedef RawTallies = {
	var combo:Int;

	/**
	 * How many notes you let scroll by.
	 */
	var missed:Int;

	var shit:Int;
	var bad:Int;
	var good:Int;
	var sick:Int;
	var maxCombo:Int;
	var score:Int;
	var isNewHighscore:Bool;

	/**
	 * How many notes total that you hit. (NOT how many notes total in the song!)
	 */
	var totalNotesHit:Int;

	/**
	 * How many notes in the current chart
	 */
	var totalNotes:Int;
}

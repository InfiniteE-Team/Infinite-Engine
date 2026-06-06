package game;

class PlayStateConfig {
	// note
	public static inline var strumLineY:Float = 50.0;

	// gameplay
	public var health:Float = 1.0;

	public var score:Int = 0;

	public var misses:Int = 0;

	public var combo:Int = 0;

	// accuracy
	public var accuracy:Float = 0.0;
	public var totalNotesHit:Int = 0;
	public var totalAccuracyWeight:Float = 0.0;

	public var rating:String = "N/A";

	//

	public function new() {}

	public function reset() {
		health = 1.0;
		score = 0;
		misses = 0;
		accuracy = 0.0;
		rating = "N/A";
		totalNotesHit = 0;
        totalAccuracyWeight = 0.0;
		combo = 0;
	}

	public function configRating(rating:String) {
		this.rating = rating;
	}
}

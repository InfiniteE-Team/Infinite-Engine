package core.rhythm;

import sys.FileSystem;

class DiffsUtils {
	public static var difficulties:Array<String> = [];

	public static var diffCurrent:String = '';

	public static var defaultOrder:Array<String> = ["easy", "", "normal", "hard", "erect"];

	public function new() {}

	public static function getDifficulty(curSong:String) {
		difficulties = [];
		var diffsDir = Paths.findLib('songs/$curSong/charts/');

		if (FileSystem.exists(diffsDir)) {
			for (file in sys.FileSystem.readDirectory(diffsDir)) {
				var diffName = file.replace('.json', '').replace('.osu', '');

				if (diffName.startsWith(curSong + '-'))
					diffName = diffName.replace('$curSong-', '');
				else if (diffName == curSong)
					diffName = '';

				if (!difficulties.contains(diffName))
					difficulties.push(diffName);
			}
		}

		if (difficulties.length == 0) {
			difficulties.push(""); // normal diff
		}

		difficulties.sort(function(a:String, b:String):Int {
			var iA = defaultOrder.indexOf(a.toLowerCase());
			var iB = defaultOrder.indexOf(b.toLowerCase());

			if (iA == -1)
				iA = 999;
			if (iB == -1)
				iB = 999;

			return iA - iB;
		});

		if (diffCurrent == '' || !difficulties.contains(diffCurrent)) {
			diffCurrent = difficulties[0];
		}
	}

	public static function getDiffIndex(diff:String):Int {
		return difficulties.indexOf(diff);
	}
}

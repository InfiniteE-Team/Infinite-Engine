package core.system.warnings;

import sys.io.File;
import sys.FileSystem;
import lime.app.Application;

class TroubleShooter {
	public function new() {}

	public function launchCrash(errorMessage:String) {
		var dateNow:String = Date.now().toString().split(" ").join("_").split(":").join("-");
		var folderCrash:String = "./crash/";
		var archive:String = folderCrash + "InfiniteEngine_Crash_" + dateNow + ".txt";

		try {
			if (!FileSystem.exists(folderCrash)) {
				FileSystem.createDirectory(folderCrash);
			}
			File.saveContent(archive, errorMessage + "\n\n> Crash Handler by InfiniteTeam");
		} catch (e:Dynamic) {
			Sys.println("The TXT report could not be created: " + Std.string(e));
		}

		Sys.println(errorMessage);

		if (Application.current != null && Application.current.window != null) {
			Application.current.window.alert(errorMessage, "Infinite Engine - Crash!");
		}

		Sys.exit(1);
	}
}

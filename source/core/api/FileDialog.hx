package core.api;

import sys.io.Process;

class FileDialog {
	public static function open(title:String, filter:String, onSelect:String->Void) {
		sys.thread.Thread.create(() -> {
			var path:String = null;
			#if windows
			var dollar = '\x24';
			var ps = 'Add-Type -AssemblyName System.Windows.Forms; '
				+ '${dollar}f = New-Object System.Windows.Forms.OpenFileDialog; '
				+ '[void]${dollar}f.ShowDialog(); '
				+ 'Write-Output ${dollar}f.FileName';
			var process = new Process('powershell', ['-Command', ps]);
			path = process.stdout.readLine().trim();
			process.close();
			#elseif mac
			var process = new Process('osascript', ['-e', 'POSIX path of (choose file with prompt "$title")']);
			path = process.stdout.readLine().trim();
			process.close();
			#elseif linux
			var process = new Process('zenity', ['--file-selection', '--title=$title']);
			path = process.stdout.readLine().trim();
			process.close();
			#end

			if (path != null && path.length > 0) {
				var listener:openfl.events.Event->Void = null;
				listener = function(e) {
					openfl.Lib.application.window.stage.removeEventListener(openfl.events.Event.ENTER_FRAME, listener);
					onSelect(path);
				};
				openfl.Lib.application.window.stage.addEventListener(openfl.events.Event.ENTER_FRAME, listener);
			}
		});
	}
}

package core.api;

import sys.io.Process;

class FileDialog {
	public static function open(title:String, filter:String, onSelect:String->Void) {
		sys.thread.Thread.create(() -> {
			var path:String = null;
			#if windows
			var dollar = '\x24';
			var powerShellFilter = StringTools.replace(filter, "'", "''");
			var powerShellTitle = StringTools.replace(title, "'", "''");
			var powerShell = 'Add-Type -AssemblyName System.Windows.Forms; '
				+ '${dollar}f = New-Object System.Windows.Forms.OpenFileDialog; '
				+ '${dollar}f.Title = \'$powerShellTitle\'; '
				+ '${dollar}f.Filter = \'$powerShellFilter\'; '
				+ '[void]${dollar}f.ShowDialog(); '
				+ 'Write-Output ${dollar}f.FileName';
			var process = new Process('powershell', ['-Command', powerShell]);
			path = process.stdout.readLine().trim();
			process.close();
			#elseif mac
			var extList = extractExtensions(filter).map(e -> '"$e"').join(', ');
			var script = extList.length > 0
				? 'POSIX path of (choose file of type {$extList} with prompt "$title")'
				: 'POSIX path of (choose file with prompt "$title")';
			var process = new Process('osascript', ['-e', script]);
			path = process.stdout.readLine().trim();
			process.close();
			#elseif linux
			var args = ['--file-selection', '--title=$title'];
			var parts = filter.split('|');
			var i = 0;
			while (i + 1 < parts.length) {
				var label = parts[i];
				var patterns = StringTools.replace(parts[i + 1], ';', ' ');
				args.push('--file-filter=$label | $patterns');
				i += 2;
			}
			var process = new Process('zenity', args);
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

	static function extractExtensions(filter:String):Array<String> {
		var result:Array<String> = [];
		var parts = filter.split('|');
		var i = 1;
		while (i < parts.length) {
			for (pat in parts[i].split(';')) {
				var e = StringTools.replace(pat.trim(), '*.', '').toLowerCase();
				if (e.length > 0 && e != '*')
					result.push(e);
			}
			i += 2;
		}
		return result;
	}
}

var optionsGroup:Array<FlxText> = [];

function onCreate() {
	options = ['Gameplay', 'Keybinds', 'Graphics'];

	for (i in 0...options.length) {
		var text:FlxText = new FlxText(100 + (i * 60), 100, FlxG.width, options[i]);
		text.setFormat(Paths.getPath('Funkin.otf', 'font'), 34, 0xFFFFFFFF, "center");
		text.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		text.antialiasing = true;
		text.scrollFactor.set(0, 0);
		optionsGroup.push(text);
		add(text);
	}
}

function onUpdate(elapsed:Float) {}

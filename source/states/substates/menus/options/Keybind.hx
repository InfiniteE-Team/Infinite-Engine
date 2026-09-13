package states.substates.menus.options;

class Keybind extends core.assets.FunkinSprite {
	public var keyLabel:flixel.text.FlxText;

	public function new(x:Float, y:Float, keybind:String) {
		super(x, y, true);
		this.x = x;
		this.y = y;
		keyLabel = new flixel.text.FlxText(0, -20, 60, '', 38);
		keyLabel.setFormat(Paths.getPath('Funkin.otf', 'font'), 38, 0xFF000000, 'center');
		keyLabel.antialiasing = SaveData.data.antialiasing;
		loadSprite(keybind);
	}

	public function setKeyLabel(text:String) {
		keyLabel.text = text;
		keyLabel.setPosition(x + (width - keyLabel.width) / 2, y + (height - keyLabel.height) / 2);
	}

	public function loadSprite(keybind:String) {
		if (animation.curAnim?.name == keybind)
			return;
		if (frames == null)
			frames = Paths.getPath('menus/options/keybinds/KEYBINDS', 'animated');
		if (animation.getByName(keybind) == null)
			addAnim(keybind, keybind + '0000', 24, false);
		playAnim(keybind);
		updateHitbox();
	}
}

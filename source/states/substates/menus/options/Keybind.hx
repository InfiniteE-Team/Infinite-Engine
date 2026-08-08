package states.substates.menus.options;

class Keybind extends core.assets.FunkinSprite {
	public function new(x:Float, y:Float, keybind:String) {
		super();
		this.x = x;
		this.y = y;
		loadSprite(keybind);
	}

	public function loadSprite(keybind:String) {
		frames = Paths.getPath('menus/options/keybinds/KEYBINDS', 'animated');
		addAnim(keybind, keybind+'0000', 24, true);
		playAnim(keybind);
        updateHitbox();
	}
}

package states.substates.menus.options;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;
import core.assets.FunkinSprite;
import game.objects.sprites.notes.StrumNote;
import core.json.objects.NoteSkinData;

class KeybindsMenu extends flixel.group.FlxGroup {
	var curKeyCount:Int = 4;
	var minKeys:Int = 1;
	var maxKeys:Int = 9;

	var keyCountSprite:FunkinSprite;
	var keyCountText:FlxText;

	var keySprites:Array<Array<Keybind>> = [];

	var uiKeyRows:Array<FlxText> = [];
	var uiKeySprites:Array<Array<Keybind>> = [];

	var curRow:Int = 0;
	var curCol:Int = 0;
	var isListening:Bool = false;

	static final KEY_FRAME_MAP:Map<String, String> = [
		'LEFT' => 'TeclaLeft',
		'RIGHT' => 'TeclaRight',
		'UP' => 'TeclaUP',
		'DOWN' => 'TeclaDown',
		'ENTER' => 'TeclaEnter',
		'ESCAPE' => 'TeclaEsc',
		'BACKSPACE' => 'TeclaBackspace',
		'SHIFT' => 'TeclaShifI',
		'CONTROL' => 'TeclaCtrl',
		'ALT' => 'TeclaAlt',
		'SPACE' => 'TeclaSpace',
		'TAB' => 'TeclaTab',
		'CAPSLOCK' => 'TeclaCapslock',
		'Ñ' => 'TeclaÑ',
	];

	static final BASE_X:Float = 40;
	static final BASE_Y:Float = 50;
	static final COL_W:Float = 80;
	static final ROW_H:Float = 70;

	var uiActionNames:Array<String> = ['Left', 'Up', 'Down', 'Right', 'Accept', 'Escape', 'Death'];

	var contentCam:game.objects.Camera;

	public function new(cam:game.objects.Camera) {
		super();
		this.contentCam = cam;
		build();
	}

	// var resetBtn:FunkinSprite;
	var setLabels:Array<FlxText> = [];

	public function build() {
		var keysLabel = makeText(BASE_X, BASE_Y - 40, 'Keys', 26);
		add(keysLabel);

		keyCountSprite = new FunkinSprite(BASE_X + 50, BASE_Y - 54, true);
		keyCountSprite.frames = Paths.getPath('menus/options/keybinds/ui/UI_KEYS', 'animated');
		keyCountSprite.addAnim('normal', 'Keysretraibles0000', 24, false);
		keyCountSprite.addAnim('selected', 'Keysretraibles_ON0000', 24, false);
		keyCountSprite.playAnim('normal');
		keyCountSprite.cameras = [contentCam];
		keyCountSprite.scale.set(0.5, 0.5);
		keyCountSprite.updateHitbox();
		add(keyCountSprite);

		keyCountText = makeText(BASE_X + 90, BASE_Y - 38, '$curKeyCount', 22);
		add(keyCountText);

		buildNoteKeys();
		var uiStartY = BASE_Y + 80 + 2 * ROW_H + 30;
		buildUiKeys(uiStartY);

		refreshVisuals();
		/*
			resetBtn = new FunkinSprite(BASE_X + 200, BASE_Y - 54, false);
			resetBtn.makeGraphic(200, 40, 0xFFFF5555);
			resetBtn.cameras = [contentCam];
			resetBtn.scrollFactor.set(0, 0);
			add(resetBtn);

			var resetLabel = makeText(BASE_X + 220, BASE_Y - 46, 'Reset to Default', 18);
			resetLabel.color = 0xFF000000;
			resetLabel.cameras = [contentCam];
			resetLabel.scrollFactor.set(0, 0);
			add(resetLabel); */
	}

	var laneStrums:Array<StrumNote> = [];

	function buildNoteKeys() {
		for (arr in keySprites) {
			for (k in arr) {
				remove(k.keyLabel);
				k.keyLabel.destroy();
				remove(k);
				k.destroy();
			}
		}
		for (s in laneStrums) {
			remove(s);
			s.destroy();
		}
		for (s in setLabels) {
			remove(s);
			s.destroy();
		}
		setLabels = [];
		laneStrums = [];
		keySprites = [];

		var noteSkinData:NoteSkinData = FormatJson.readJson(Paths.getPath('data/noteskins/default/strumnotes', 'json'));
		if (noteSkinData == null)
			return;

		var preset = getPreset(curKeyCount);
		if (preset == null)
			return;

		var strumsX:Float = BASE_X + 100;
		for (lane in 0...curKeyCount) {
			var strum = new StrumNote(strumsX, BASE_Y - 10, noteSkinData.props, 'default');
			strum.playAnim('static$lane');
			strum.applyShader(noteSkinData);
			strum.scale.set(0.5, 0.5);
			strum.updateHitbox();
			strum.cameras = [contentCam];
			add(strum);
			laneStrums.push(strum);
			strumsX += strum.width + 5;
		}

		for (set in 0...2) {
			var setLabel = makeText(BASE_X, BASE_Y + 100 + set * ROW_H, 'Set ${set + 1}', 22);
			setLabel.cameras = [contentCam];
			add(setLabel);
			setLabels.push(setLabel);

			var rowSprites:Array<Keybind> = [];
			var currentX:Float = BASE_X + 100;
			for (lane in 0...curKeyCount) {
				var keyStr = (preset[lane] != null && preset[lane][set] != null) ? preset[lane][set] : '?';
				var sprite = makeKeybindSprite(currentX, BASE_Y + 80 + set * ROW_H, keyStr, false);
				sprite.cameras = [contentCam];
				sprite.keyLabel.cameras = [contentCam];
				add(sprite);
				add(sprite.keyLabel);
				rowSprites.push(sprite);
				currentX += sprite.width + 5;
			}
			keySprites.push(rowSprites);
		}
	}

	function buildUiKeys(startY:Float) {
		for (arr in uiKeySprites) {
			for (k in arr) {
				remove(k.keyLabel);
				k.keyLabel.destroy();
				remove(k);
				k.destroy();
			}
		}
		for (t in uiKeyRows) {
			remove(t);
			t.destroy();
		}
		uiKeySprites = [];
		uiKeyRows = [];

		var uiLabel = makeText(BASE_X, startY, 'UI Key Bindings', 20);
		uiLabel.color = 0xFFAAAAAA;
		uiKeyRows.push(uiLabel);
		add(uiLabel);

		var uiKeys = SaveData.data.uiKeys;
		if (uiKeys == null)
			return;

		for (i in 0...uiActionNames.length) {
			var label = makeText(BASE_X, startY + 50 + i * 70, uiActionNames[i], 22);
			uiKeyRows.push(label);
			add(label);

			var rowSprites:Array<Keybind> = [];
			var currentX:Float = BASE_X + 100;
			for (set in 0...2) {
				var keyStr = (uiKeys[i] != null && uiKeys[i][set] != null && uiKeys[i][set] != 'NONE') ? uiKeys[i][set] : '?';
				var sprite = makeKeybindSprite(currentX, startY + 30 + i * 70, keyStr, false);
				sprite.cameras = [contentCam];
				sprite.keyLabel.cameras = [contentCam];
				add(sprite);
				add(sprite.keyLabel);
				rowSprites.push(sprite);
				currentX += sprite.width + 5;
			}
			uiKeySprites.push(rowSprites);
		}
	}

	function makeKeybindSprite(x:Float, y:Float, keyStr:String, selected:Bool):Keybind {
		var frameName = getFrameName(keyStr, selected);
		var k = new Keybind(x, y, frameName);
		return k;
	}

	function getFrameName(keyStr:String, selected:Bool):String {
		var upper = keyStr.toUpperCase();
		var base = KEY_FRAME_MAP.get(upper);
		if (base == null)
			base = selected ? 'Tecla_selct' : 'Tecla';
		else
			base = selected ? base + '_selct' : base;
		return base;
	}

	function getPreset(count:Int):Array<Array<String>> {
		var raw:Dynamic = SaveData.data.noteKeyPresets;
		if (raw == null)
			return null;
		var lanesRaw:Dynamic = Reflect.field(raw, Std.string(count));
		if (lanesRaw == null)
			return null;
		var lanes:Array<Dynamic> = lanesRaw;
		return [
			for (lane in lanes) {
				var l:Array<Dynamic> = lane;
				[for (k in l) Std.string(k)];
			}
		];
	}

	public function refreshVisuals() {
		keyCountText.text = '$curKeyCount';

		for (a in laneStrums)
			a.visible = true;
		for (arr in keySprites)
			for (k in arr)
				k.visible = true;
		for (t in uiKeyRows)
			t.visible = true;
		for (arr in uiKeySprites)
			for (k in arr)
				k.visible = true;

		keyCountSprite.playAnim(curRow == -1 ? 'selected' : 'normal');

		for (set in 0...keySprites.length) {
			for (lane in 0...keySprites[set].length) {
				var selected = !isListening && set == curRow && lane == curCol;
				var listening = isListening && set == curRow && lane == curCol;
				var preset = getPreset(curKeyCount);
				var keyStr = (preset != null && preset[lane] != null && preset[lane][set] != null) ? preset[lane][set] : '?';
				refreshKeybindSprite(keySprites[set][lane], keyStr, selected || listening);
			}
		}

		var uiKeys = SaveData.data.uiKeys;
		for (i in 0...uiKeySprites.length) {
			for (set in 0...uiKeySprites[i].length) {
				var selected = !isListening && (i + keySprites.length) == curRow && set == curCol;
				var listening = isListening && (i + keySprites.length) == curRow && set == curCol;
				var keyStr = (uiKeys != null && uiKeys[i] != null && uiKeys[i][set] != null) ? uiKeys[i][set] : '?';
				refreshKeybindSprite(uiKeySprites[i][set], keyStr, selected || listening);
			}
		}
	}

	function refreshKeybindSprite(sprite:Keybind, keyStr:String, selected:Bool) {
		var upper = keyStr.toUpperCase();
		var hasSpecialFrame = KEY_FRAME_MAP.exists(upper);
		var frameName = getFrameName(keyStr, selected);
		sprite.loadSprite(frameName);
		sprite.keyLabel.text = hasSpecialFrame ? '' : keyStr;
		sprite.keyLabel.setPosition(sprite.x + (sprite.width - sprite.keyLabel.width) / 2, sprite.y + (sprite.height - sprite.keyLabel.height) / 2);
		sprite.keyLabel.visible = sprite.visible;
	}

	/*
		override public function update(elapsed:Float) {
			super.update(elapsed);

			if (FlxG.mouse.justPressed) {
				if (FlxG.mouse.overlaps(resetBtn, contentCam)) {
					resetToDefault();
					FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
				}
			}
	}*/
	function resetToDefault() {
		SaveData.data.noteKeyPresets = null;
		SaveData.data.uiKeys = [
			['LEFT', 'A'],
			['UP', 'W'],
			['DOWN', 'S'],
			['RIGHT', 'D'],
			['ENTER', 'NONE'],
			['ESCAPE', 'NONE'],
			['R', 'NONE']
		];
		SaveData.flush();

		Controls.instance.setKey('uiKeys', 0, 0, FlxKey.LEFT);
		Controls.instance.setKey('uiKeys', 0, 1, FlxKey.A);
		Controls.instance.setKey('uiKeys', 1, 0, FlxKey.UP);
		Controls.instance.setKey('uiKeys', 1, 1, FlxKey.W);
		Controls.instance.setKey('uiKeys', 2, 0, FlxKey.DOWN);
		Controls.instance.setKey('uiKeys', 2, 1, FlxKey.S);
		Controls.instance.setKey('uiKeys', 3, 0, FlxKey.RIGHT);
		Controls.instance.setKey('uiKeys', 3, 1, FlxKey.D);
		Controls.instance.setKey('uiKeys', 4, 0, FlxKey.ENTER);
		Controls.instance.setKey('uiKeys', 4, 1, FlxKey.NONE);
		Controls.instance.setKey('uiKeys', 5, 0, FlxKey.ESCAPE);
		Controls.instance.setKey('uiKeys', 5, 1, FlxKey.NONE);
		Controls.instance.setKey('uiKeys', 6, 0, FlxKey.R);
		Controls.instance.setKey('uiKeys', 6, 1, FlxKey.NONE);

		buildNoteKeys();
		buildUiKeys(BASE_Y + 80 + 2 * ROW_H + 30);
		refreshVisuals();
	}

	public function handleInput() {
		if (isListening) {
			@:privateAccess
			var pressed = FlxG.keys.firstJustPressed();
			if (pressed != FlxKey.NONE && pressed != FlxKey.BACKSPACE) {
				applyKey(pressed);
				isListening = false;
				refreshVisuals();
			} else if (FlxG.keys.justPressed.BACKSPACE) {
				isListening = false;
				refreshVisuals();
			}
			return;
		}

		if (Controls.UI_UP) {
			if (curRow == 0)
				curRow = -1;
			else if (curRow == -1)
				curRow = getRowCount() - 1;
			else
				curRow--;

			if (curRow != -1 && curCol >= getColCount()) {
				curCol = getColCount() - 1;
			}

			FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));
			refreshVisuals();
			updateScroll();
		}

		if (Controls.UI_DOWN) {
			if (curRow == -1)
				curRow = 0;
			else if (curRow == getRowCount() - 1)
				curRow = -1;
			else
				curRow++;

			if (curRow != -1 && curCol >= getColCount()) {
				curCol = getColCount() - 1;
			}

			FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));
			refreshVisuals();
			updateScroll();
		}

		if (Controls.UI_LEFT) {
			if (curRow == -1) {
				curKeyCount = Std.int(Math.max(minKeys, curKeyCount - 1));
				buildNoteKeys();
				var uiStartY = BASE_Y + 80 + 2 * ROW_H + 30;
				buildUiKeys(uiStartY);
			} else {
				curCol = (curCol - 1 + getColCount()) % getColCount();
			}
			FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));
			refreshVisuals();
		}

		if (Controls.UI_RIGHT) {
			if (curRow == -1) {
				curKeyCount = Std.int(Math.min(maxKeys, curKeyCount + 1));
				buildNoteKeys();
				var uiStartY = BASE_Y + 80 + 2 * ROW_H + 30;
				buildUiKeys(uiStartY);
			} else {
				curCol = (curCol + 1) % getColCount();
			}
			FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'));
			refreshVisuals();
		}

		if (Controls.ACCEPT) {
			if (curRow == -1) {} else {
				isListening = true;
				FlxG.sound.play(Paths.getPath('menus/confirmMenu', 'sound'));
				refreshVisuals();
			}
		}
	}

	function updateScroll() {
		if (contentCam == null)
			return;
		if (curRow == -1) {
			contentCam.scroll.y = 0;
			return;
		}

		if (curRow == getRowCount() - 1) {
			var lastItemY = getRowY(curRow);
			contentCam.scroll.y = Math.max(0, lastItemY + ROW_H - contentCam.height);
			return;
		}

		var targetY:Float = getRowY(curRow);
		var camBottom:Float = contentCam.scroll.y + contentCam.height;

		if (targetY < contentCam.scroll.y)
			contentCam.scroll.y = targetY;
		else if (targetY + ROW_H > camBottom)
			contentCam.scroll.y = targetY + ROW_H - contentCam.height;

		contentCam.scroll.y = Math.max(0, contentCam.scroll.y);
	}

	function getRowY(row:Int):Float {
		if (row < keySprites.length) {
			return BASE_Y + 80 + row * ROW_H;
		} else {
			var uiStartY = BASE_Y + 80 + 2 * ROW_H + 30;
			var uiRow = row - keySprites.length;
			return uiStartY + 35 + uiRow * 70;
		}
	}

	function getRowCount():Int {
		return keySprites.length + uiKeySprites.length;
	}

	function getColCount():Int {
		return curRow < keySprites.length ? curKeyCount : 2;
	}

	function applyKey(key:FlxKey) {
		var keyStr = key.toString();

		if (curRow < keySprites.length) {
			var preset = getPreset(curKeyCount);
			for (lane in 0...preset.length) {
				for (set in 0...preset[lane].length) {
					if (preset[lane][set] == keyStr && !(lane == curCol && set == curRow)) {
						var oldKeyStr = preset[curCol][curRow];
						var oldKey = FlxKey.fromString(oldKeyStr);
						if (oldKey != FlxKey.NONE)
							Controls.instance.setKey('noteKeys', lane, set, oldKey);
					}
				}
			}
			Controls.instance.setKey('noteKeys', curCol, curRow, key);
			buildNoteKeys();
			buildUiKeys(BASE_Y + 80 + 2 * ROW_H + 30);
		} else {
			var uiKeys = SaveData.data.uiKeys;
			var uiRow = curRow - keySprites.length;
			for (i in 0...uiKeys.length) {
				for (set in 0...uiKeys[i].length) {
					if (uiKeys[i][set] == keyStr && !(i == uiRow && set == curCol)) {
						var oldKeyStr = uiKeys[uiRow][curCol];
						var oldKey = FlxKey.fromString(oldKeyStr);
						if (oldKey != FlxKey.NONE)
							Controls.instance.setKey('uiKeys', i, set, oldKey);
					}
				}
			}
			Controls.instance.setKey('uiKeys', uiRow, curCol, key);
			buildUiKeys(BASE_Y + 80 + 2 * ROW_H + 30);
		}

		SaveData.flush();
		refreshVisuals();
	}

	function makeText(x:Float, y:Float, text:String, size:Int):FlxText {
		var t = new FlxText(x, y, 0, text);
		t.setFormat(Paths.getPath('Funkin.otf', 'font'), size, 0xFFFFFFFF, 'left');
		t.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		t.antialiasing = SaveData.data.antialiasing;
		t.cameras = [contentCam];
		return t;
	}
}

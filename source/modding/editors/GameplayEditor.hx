package modding.editors;

import game.objects.Camera;
import flixel.util.FlxColor;
import core.rhythm.RhythmCore;
import core.rhythm.audio.GameAudio;
import core.json.song.SongData.SongConfig;
import flixel.addons.display.FlxGridOverlay;
import modding.editors.gameplay.ChartDefaults;
import modding.editors.gameplay.EditorWidgets;
import modding.editors.gameplay.PreviewEvents;

typedef NoteEntry = {
	var data:core.json.song.SongData.NoteData;
	var head:flixel.FlxSprite;
	var tail:flixel.FlxSprite;

	var mark:flixel.FlxSprite;

	var typeMark:flixel.FlxSprite;
}

typedef EventEntry = {
	var data:core.json.song.SongData.EventsData;
	var box:flixel.FlxSprite;
	var label:flixel.text.FlxText;
}

typedef ChartSnapshot = {
	var notes:Array<core.json.song.SongData.NoteData>;
	var events:Array<core.json.song.SongData.EventsData>;
}

class GameplayEditor extends MusicBeatState {
	var acceptOption:Bool = false;

	public var gameAudio:GameAudio = new GameAudio();

	public static var SONG:SongConfig;

	var isPlaying:Bool = false;

	var GRID_SIZE:Int = 32;
	var COLUMNS:Int = 4;

	static final GRID_X:Float = 100;

	static final CHUNK_ROWS:Int = 64;

	static final PREVIEW_SCALE:Float = 0.85;
	static final PREVIEW_TOP:Int = 158;

	static final HEADER_H:Int = 80;
	static final HEADER_COLOR:Int = 0xFF3A3A3A;
	static final HEADER_LINE_COLOR:Int = 0xFFCCCCCC;
	static final ICON_SIZE:Float = 52;

	public static var diff:String = null;

	public static var folder:String = null;

	public static function open(song:String, diffName:String = 'normal', bpm:Float = 120, stage:String = 'stage'):Void {
		var config = new SongConfig();
		try {
			config.configSong(song, diffName);
		} catch (e:Dynamic) {
			trace('GameplayEditor: could not read "$song" ($diffName): $e');
			config.songData = null;
		}

		if (config.songData == null) {
			config.songData = ChartDefaults.blankChart(song, bpm, stage);
			config.songName = song;
			config.bpmSong = config.songData.meta.bpm;
			config.stage = stage;
			config.chars = config.songData.gameplay.chars;
		}

		SONG = config;
		diff = diffName;
		folder = song;
		MusicBeatState.switchState(() -> new GameplayEditor());
	}

	static var askForNewChart:Bool = false;

	public static function openNew():Void {
		askForNewChart = true;
		open('untitled', 'normal', ChartDefaults.DEFAULT_BPM);
	}

	static final NOTE_COLORS:Array<Int> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];

	var gridChunks:flixel.group.FlxGroup;
	var noteGroup:flixel.group.FlxGroup;
	var playhead:flixel.FlxSprite;

	var charColumnOffset:Map<String, Int> = new Map();
	var columnLabels:Array<{id:String, text:String, role:String, column:Int, lanes:Int}> = [];
	var noteBitmaps:Array<openfl.display.BitmapData> = [];

	var arrowTemplates:Map<String, Array<game.objects.sprites.notes.Note>> = new Map();
	var charSkins:Map<String, String> = new Map();

	var camEditor:Camera;
	var camHud:Camera;
	var camGameplay:Camera;

	var director:PreviewEvents = null;
	var previewLabel:flixel.text.FlxText;
	var previewDirty:Bool = false;
	var previewLastPos:Float = -1;
	var previewSignature:String = '';

	var columnOwners:Array<{char:String, lane:Int}> = [];
	var noteEntries:Array<NoteEntry> = [];
	var totalSteps:Int = 0;
	var hoverBox:flixel.FlxSprite;
	var mousePoint:flixel.math.FlxPoint = flixel.math.FlxPoint.get();

	var selected:Array<NoteEntry> = [];
	var moveOrigins:Array<{entry:NoteEntry, col:Int, time:Float}> = null;
	var moveAnchorCol:Int = 0;
	var moveAnchorRow:Float = 0;
	var moveDeltaCol:Int = 0;
	var moveDeltaRows:Float = 0;
	var boxActive:Bool = false;
	var boxStartX:Float = 0;
	var boxStartY:Float = 0;
	var boxBase:Array<NoteEntry> = [];
	var boxSprite:flixel.FlxSprite;

	var dragEntry:NoteEntry = null;
	var dragStartRow:Float = 0;

	var sortedNotes:Array<core.json.song.SongData.NoteData> = [];
	var sustainNotes:Array<core.json.song.SongData.NoteData> = [];
	var noteIndex:Int = 0;

	var previousLogInScreen:Null<Bool> = null;

	var dirty:Bool = false;
	var leaveArmed:Bool = false;
	var statusText:flixel.text.FlxText;
	var helpText:flixel.text.FlxText;
	var helpBar:flixel.FlxSprite;
	var nowLabel:flixel.text.FlxText;

	var songDir:String = '';
	var chartDiff:String = 'normal';

	var ready:Bool = false;
	var isNewChart:Bool = false;

	var hasAudio:Bool = false;
	var songLength:Float = 0;
	static final SILENT_MIN_MS:Float = 120000;

	var startupNotes:Array<String> = [];

	var headerGroup:flixel.group.FlxGroup;

	var previewW:Int = 0;
	var previewH:Int = 0;

	static final MAX_UNDO:Int = 100;
	var undoStack:Array<ChartSnapshot> = [];
	var redoStack:Array<ChartSnapshot> = [];
	var moveSnapshot:ChartSnapshot = null;

	static final SNAPS:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64];
	static final SPEEDS:Array<Float> = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 2];
	var snapIndex:Int = 3;
	var speedIndex:Int = 3;
	var noteType:String = 'normal';
	var customTypes:Array<String> = [];
	var metronome:Bool = false;
	var hitsounds:Bool = false;
	var toolText:flixel.text.FlxText;

	var clipboard:Array<{col:Int, dt:Float, data:core.json.song.SongData.NoteData}> = [];

	var eventGroup:flixel.group.FlxGroup;
	var eventEntries:Array<EventEntry> = [];
	var lastEventName:String = 'Camera Follow';

	var panel:OptionPanel;
	var panelMode:String = '';
	var panelRow:Int = 0;
	var panelEvent:EventEntry = null;
	var panelUndoPushed:Bool = false;
	var prompt:TextPrompt = new TextPrompt();

	var lastPosition:Float = 0;

	var stage:game.objects.sprites.Stage;
	var chars:game.controllers.CharacterController;

	var infoHUD:InfoHUD;

	var railX:Float = 0;
	var railW:Int = 0;
	var toolCard:flixel.FlxSprite;
	var titleText:flixel.text.FlxText;
	var helpTopLine:flixel.FlxSprite;

	static var viewState:Array<Bool> = [true, true, true, true];
	var viewToggles:ViewToggles;

	static final SCROLL_MS:Float = 100.0;

	public function new() {
		super();
	}

	function initializeCameras() {
		camEditor = new Camera();
		camHud = new Camera();
		camHud.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHud, false);
	}

	override public function create() {
		super.create();

		songDir = folder != null && folder != '' ? folder : (game.PlayState.instance?.curSong ?? SONG?.songName ?? 'untitled');
		folder = null;
		chartDiff = pickDiffName();
		diff = null;

		game.PlayState.instance = null;

		previousLogInScreen = SaveData.data.logInScreen;
		SaveData.data.logInScreen = false;
		utils.Trace.updateVisibility();

		if (infoHelp != null)
			infoHelp.visible = false;

		if (core.ui.FPSCounter.instance != null)
			core.ui.FPSCounter.instance.visible = false;

		initializeCameras();

		var askNow:Bool = askForNewChart;
		askForNewChart = false;

		try {
			buildEditor();
			ready = true;
			if (askNow)
				askNewChart(0);
		} catch (e:Dynamic) {
			ready = false;
			showFatal(e);
		}

		FlxG.mouse.visible = true;
	}

	function safe(step:String, fn:() -> Void):Bool {
		try {
			fn();
			return true;
		} catch (e:Dynamic) {
			trace('GameplayEditor: "$step" failed: $e');
			startupNotes.push('Could not build the $step: $e');
			return false;
		}
	}

	function buildEditor():Void {
		prepareChart();

		add(gameAudio);

		Paths.currentSong = songDir;
		safe('audio', () -> {
			gameAudio.loadSong(SONG, SONG.needVoices, endSong);
			gameAudio.pauseAll();
		});

		hasAudio = gameAudio.inst != null && gameAudio.inst.length > 0;
		if (!hasAudio)
			startupNotes.push('No audio found for "$songDir" (songs/$songDir/audio/Inst): the timeline runs silently.');

		RhythmCore.reset(SONG.bpmSong);
		t.reset();

		songLength = songLengthMs();

		buildColumns();
		buildGrid(songLength);
		buildNotes();
		buildEvents();
		safe('gameplay preview', buildGameplayView);
		prepareSinging();

		playhead = new flixel.FlxSprite(GRID_X, FlxG.height * 0.5).makeGraphic(GRID_SIZE * (COLUMNS + 1), 4, FlxColor.YELLOW);
		playhead.scrollFactor.set(0, 0);
		add(playhead);

		nowLabel = new flixel.text.FlxText(GRID_X - 44, FlxG.height * 0.5 - 8, 40, 'NOW', 12);
		nowLabel.setFormat(null, 12, FlxColor.YELLOW, RIGHT, OUTLINE, FlxColor.BLACK);
		nowLabel.scrollFactor.set(0, 0);
		nowLabel.cameras = [camHud];
		add(nowLabel);

		hoverBox = new flixel.FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, 0x55FFFFFF);
		hoverBox.visible = false;
		add(hoverBox);

		boxSprite = new flixel.FlxSprite().makeGraphic(1, 1, 0x55FFFF66);
		boxSprite.visible = false;
		add(boxSprite);

		layoutRail();

		titleText = new flixel.text.FlxText(railX, 8, railW, '', 16);
		titleText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		titleText.text = '$songDir  /  $chartDiff';
		titleText.scrollFactor.set(0, 0);
		titleText.cameras = [camHud];
		add(titleText);

		var brand = new flixel.text.FlxText(railX, 12, railW, 'GAMEPLAY EDITOR', 10);
		brand.setFormat(null, 10, EditorWidgets.MUTED, RIGHT);
		brand.scrollFactor.set(0, 0);
		brand.cameras = [camHud];
		add(brand);

		infoHUD = new InfoHUD(railX, 34, railW);
		infoHUD.cameras = [camHud];
		add(infoHUD);

		safe('role headers', buildHeaders);

		helpBar = new flixel.FlxSprite(0, FlxG.height - 76).makeGraphic(FlxG.width, 76, 0xF00E0E14);
		helpBar.scrollFactor.set(0, 0);
		helpBar.cameras = [camHud];
		add(helpBar);

		helpTopLine = new flixel.FlxSprite(0, FlxG.height - 76).makeGraphic(FlxG.width, 1, EditorWidgets.CARD_BORDER);
		helpTopLine.scrollFactor.set(0, 0);
		helpTopLine.cameras = [camHud];
		add(helpTopLine);

		helpText = new flixel.text.FlxText(GRID_X, FlxG.height - 70, 0, '', 12);
		helpText.setFormat(null, 12, 0xFFE4E4EE, LEFT, OUTLINE, FlxColor.BLACK);
		helpText.applyMarkup('<k>Click<k> note   <k>Drag down<k> sustain   <k>Drag a note<k> move   <k>Right click<k> remove   <k>Space<k> play   <k>Wheel<k> scroll\n'
			+ '<k>Shift+Click/Drag<k> select   <k>Ctrl/Cmd+A/C/X/V<k> all/copy/cut/paste   <k>Del<k> delete   <k>Arrows<k> nudge   <k>Ctrl/Cmd+Z/Y<k> undo/redo\n'
			+ '<k>Q/E<k> snap   <k>T<k> note type (<k>Shift+T<k> new)   <k>M<k> metronome   <k>H<k> hit sounds   <k>F<k> camera follow   <k>, .<k> speed   <k>1-4<k> panels\n'
			+ '<k>EVT column<k> events   <k>Tab<k> setup (stage, characters, speed, BPM)   <k>Ctrl/Cmd+S<k> save   <k>Back<k> leave',
			[new flixel.text.FlxText.FlxTextFormatMarkerPair(new flixel.text.FlxText.FlxTextFormat(EditorWidgets.ACCENT), '<k>')]);
		helpText.scrollFactor.set(0, 0);
		helpText.cameras = [camHud];
		add(helpText);

		toolCard = EditorWidgets.card(railX, 84, railW, 38, camHud);
		add(toolCard);

		toolText = new flixel.text.FlxText(railX + 12, 88, railW - 24, '', 12);
		toolText.setFormat(null, 12, 0xFFE4E4EE, LEFT, OUTLINE, FlxColor.BLACK);
		toolText.scrollFactor.set(0, 0);
		toolText.cameras = [camHud];
		add(toolText);

		var statusTop:Float = PREVIEW_TOP + Math.max(previewH, 0) + 48;
		statusText = new flixel.text.FlxText(railX, statusTop, railW, '', 13);
		statusText.setFormat(null, 13, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		statusText.scrollFactor.set(0, 0);
		statusText.cameras = [camHud];
		add(statusText);

		viewToggles = new ViewToggles(railX, 128, 4, ['1 Help', '2 Time', '3 Tools', '4 Preview'], viewState, camHud);
		viewToggles.onChange = applyView;
		add(viewToggles);
		applyView();

		panel = new OptionPanel(railX, PREVIEW_TOP, railW, camHud);
		add(panel);

		refreshTools();

		if (isNewChart)
			startupNotes.unshift('New chart: Ctrl/Cmd+S will create ' + ChartDefaults.newChartPath(songDir, chartDiff));
		showStartupNotes();
	}

	function prepareChart():Void {
		if (SONG == null)
			SONG = new SongConfig();

		if (SONG.songData == null) {
			var bpm:Float = SONG.bpmSong > 0 ? SONG.bpmSong : ChartDefaults.DEFAULT_BPM;
			SONG.songData = ChartDefaults.blankChart(songDir, bpm, SONG.stage ?? ChartDefaults.FALLBACK_STAGE);
		}

		isNewChart = !chartOnDisk();

		for (fix in ChartDefaults.repair(SONG.songData, songDir))
			startupNotes.push(fix);

		SONG.songName = SONG.songData.meta.song;
		SONG.bpmSong = SONG.songData.meta.bpm;
		SONG.speed = SONG.songData.meta.speed;
		SONG.stage = SONG.songData.meta.stage ?? ChartDefaults.FALLBACK_STAGE;
		SONG.chars = SONG.songData.gameplay.chars;
	}

	static final NEW_CHART_QUESTIONS:Array<String> = ['Song folder name (letters, numbers, - and _)', 'Difficulty (for example normal or hard)', 'BPM of the song'];
	var newChartAnswers:Array<String> = ['', 'normal', '120'];

	function askNewChart(step:Int):Void {
		prompt.open('New chart ${step + 1}/${NEW_CHART_QUESTIONS.length} - ${NEW_CHART_QUESTIONS[step]}', newChartAnswers[step], function(text:String) {
			newChartAnswers[step] = text;
			if (step + 1 < NEW_CHART_QUESTIONS.length)
				askNewChart(step + 1);
			else
				applyNewChart();
		}, leaveEditor);
	}

	function applyNewChart():Void {
		var wantedDir:String = safeName(newChartAnswers[0], 'my-song');
		var wantedDiff:String = safeName(newChartAnswers[1], 'normal');

		var oldDir:String = songDir;
		var oldDiff:String = chartDiff;
		songDir = wantedDir;
		chartDiff = wantedDiff;
		if (chartOnDisk()) {
			songDir = oldDir;
			chartDiff = oldDiff;
			newChartAnswers[1] = '';
			setStatus('"$wantedDir/$wantedDiff" already exists. Choose another difficulty or folder name.', 0xFFFF5555);
			askNewChart(0);
			return;
		}

		SONG.songName = songDir;
		SONG.songData.meta.song = songDir;
		isNewChart = true;

		var bpm:Float = Std.parseFloat(newChartAnswers[2]);
		applyBpm(Math.isNaN(bpm) || bpm <= 0 ? ChartDefaults.DEFAULT_BPM : bpm);

		if (titleText != null)
			titleText.text = '$songDir  /  $chartDiff';
		setStatus('New chart: Ctrl/Cmd+S will create ' + ChartDefaults.newChartPath(songDir, chartDiff), 0xFFFFCC33);
	}

	function safeName(text:String, fallback:String):String {
		var out:String = '';
		for (i in 0...text.length) {
			var c = text.charAt(i);
			if (c == ' ')
				c = '-';
			if (~/^[A-Za-z0-9_\-]$/.match(c))
				out += c;
		}
		return out == '' ? fallback : out;
	}

	function chartOnDisk():Bool {
		for (ext in ['json', 'osu']) {
			var path = core.assets.Library.findLib('songs/$songDir/charts/$chartDiff.$ext');
			if (path != null && sys.FileSystem.exists(path))
				return true;
		}
		return false;
	}

	function songLengthMs():Float {
		if (hasAudio)
			return gameAudio.inst.length;

		var last:Float = 0;
		for (n in SONG.songData.notes)
			last = Math.max(last, n.time + n.length);
		return Math.max(SILENT_MIN_MS, last + 30000);
	}

	function showStartupNotes():Void {
		if (startupNotes.length == 0 || statusText == null)
			return;

		for (note in startupNotes)
			trace('GameplayEditor: $note');

		var shown = startupNotes.slice(0, 3);
		if (startupNotes.length > 3)
			shown.push('(${startupNotes.length - 3} more in the terminal)');

		statusText.text = shown.join('\n');
		statusText.color = 0xFFFFCC33;
		startupNotes = [];
	}

	function showFatal(e:Dynamic):Void {
		trace('GameplayEditor: could not open the editor: $e');

		var message = new flixel.text.FlxText(40, 120, FlxG.width - 80, 'The editor could not open this chart:\n$e\n\nPress back to return to the menu.', 20);
		message.setFormat(null, 20, 0xFFFF5555, LEFT, OUTLINE, FlxColor.BLACK);
		message.scrollFactor.set(0, 0);
		message.cameras = [camHud];
		add(message);
	}

	function buildColumns():Void {
		var offset:Int = 0;
		var notes = SONG.songData != null ? SONG.songData.notes : [];

		for (c in SONG.chars) {
			var lanes:Int = 4;
			for (n in notes) {
				if (n.char == c.id && n.lane + 1 > lanes)
					lanes = n.lane + 1;
			}

			charColumnOffset.set(c.id, offset);
			columnLabels.push({id: c.id, text: c.name ?? c.id, role: c.role ?? '', column: offset, lanes: lanes});
			for (lane in 0...lanes)
				columnOwners.push({char: c.id, lane: lane});
			offset += lanes;
		}

		COLUMNS = Std.int(Math.max(offset, 4));
	}

	function columnLimit(charId:String):Int {
		for (l in columnLabels) {
			if (l.id == charId)
				return l.lanes;
		}
		return 0;
	}

	function buildGrid(totalMs:Float):Void {
		var gridWidth:Int = (COLUMNS + 1) * GRID_SIZE;
		var chunkHeight:Int = CHUNK_ROWS * GRID_SIZE;

		var bmp = FlxGridOverlay.createGrid(GRID_SIZE, GRID_SIZE, gridWidth, chunkHeight, true, 0xFF2C2C2C, 0xFF1F1F1F);

		for (row in 0...CHUNK_ROWS) {
			if (row % 4 != 0)
				continue;
			var measure = row % 16 == 0;
			bmp.fillRect(new openfl.geom.Rectangle(0, row * GRID_SIZE, gridWidth, measure ? 2 : 1), measure ? 0xFF7C8793 : 0xFF555555);
		}

		for (label in columnLabels) {
			if (label.column > 0)
				bmp.fillRect(new openfl.geom.Rectangle(label.column * GRID_SIZE - 1, 0, 2, chunkHeight), 0xFFFF0000);
		}
		bmp.fillRect(new openfl.geom.Rectangle(COLUMNS * GRID_SIZE - 1, 0, 2, chunkHeight), 0xFFFF0000);

		var oldIndex:Int = gridChunks != null ? members.indexOf(gridChunks) : -1;
		if (gridChunks != null) {
			remove(gridChunks, true);
			gridChunks.destroy();
		}

		gridChunks = new flixel.group.FlxGroup();
		gridChunks.active = false;
		if (oldIndex >= 0)
			insert(oldIndex, gridChunks);
		else
			add(gridChunks);

		var totalRows:Int = Math.ceil(totalMs / RhythmCore.stepInMs) + 1;
		var chunks:Int = Math.ceil(totalRows / CHUNK_ROWS);
		totalSteps = chunks * CHUNK_ROWS;

		for (i in 0...chunks) {
			var chunk = new flixel.FlxSprite(GRID_X, i * chunkHeight);
			chunk.loadGraphic(bmp);
			chunk.active = false;
			gridChunks.add(chunk);
		}
	}

	function buildNotes():Void {
		noteGroup = new flixel.group.FlxGroup();
		noteGroup.active = false;
		add(noteGroup);

		if (SONG.songData == null)
			return;

		var size:Int = GRID_SIZE - 4;
		for (color in NOTE_COLORS) {
			var bmp = new openfl.display.BitmapData(size, size, true, 0xFF000000);
			bmp.fillRect(new openfl.geom.Rectangle(2, 2, size - 4, size - 4), color);
			noteBitmaps.push(bmp);
		}

		loadArrowTemplates();

		for (n in SONG.songData.notes)
			addNoteSprites(n);
	}

	function loadArrowTemplates():Void {
		for (c in SONG.chars) {
			var skin:String = c.strums?.noteSkin ?? SONG.noteSkin;
			charSkins.set(c.id, skin);

			if (arrowTemplates.exists(skin))
				continue;

			try {
				var skinData:core.json.objects.NoteSkinData = FormatJson.readJson(Paths.getPath('data/noteskins/$skin/strumnotes', 'json'));
				if (skinData == null)
					continue;

				var lanes:Array<game.objects.sprites.notes.Note> = [];
				for (lane in 0...(skinData.keys ?? 4))
					lanes.push(new game.objects.sprites.notes.Note(0, skinData.keys ?? 4, 0, 0, skinData, skin, lane));

				arrowTemplates.set(skin, lanes);
			} catch (e:Dynamic) {
				Trace.traceOnce('GameplayEditor: could not load note skin "$skin", using squares instead: $e', true);
			}
		}
	}

	function makeArrow(n:core.json.song.SongData.NoteData, cellX:Float, cellY:Float):flixel.FlxSprite {
		var templates = arrowTemplates.get(charSkins.get(n.char));
		if (templates == null || templates.length == 0)
			return null;

		var lane:Int = ((n.lane % templates.length) + templates.length) % templates.length;
		var tpl = templates[lane];
		if (tpl == null || tpl.frames == null)
			return null;

		var arrow = new flixel.FlxSprite();
		arrow.frames = tpl.frames;
		arrow.animation.copyFrom(tpl.animation);
		arrow.animation.play('note$lane-Scroll');
		arrow.shader = tpl.shader;

		if (arrow.frameWidth <= 0 || arrow.frameHeight <= 0) {
			arrow.destroy();
			return null;
		}
		var fit:Float = (GRID_SIZE - 2) / Math.max(arrow.frameWidth, arrow.frameHeight);
		arrow.scale.set(fit, fit);
		arrow.updateHitbox();
		arrow.setPosition(cellX + (GRID_SIZE - arrow.width) * 0.5, cellY + (GRID_SIZE - arrow.height) * 0.5);
		return arrow;
	}

	function addNoteSprites(n:core.json.song.SongData.NoteData):NoteEntry {
		if (n == null || n.char == null || !charColumnOffset.exists(n.char))
			return null;
		if (n.lane < 0 || n.lane >= columnLimit(n.char))
			return null;

		var entry:NoteEntry = {
			data: n,
			head: null,
			tail: null,
			mark: null,
			typeMark: null
		};
		createSprites(entry);
		noteEntries.push(entry);
		return entry;
	}

	inline function snapRows():Float
		return 16 / SNAPS[snapIndex];

	inline function snapRow(worldY:Float):Float
		return Math.floor(worldY / GRID_SIZE / snapRows() + 0.0001) * snapRows();

	inline function rowTime(row:Float):Float
		return row * RhythmCore.stepInMs;

	inline function timeRow(ms:Float):Float
		return ms / RhythmCore.stepInMs;

	inline function cellX(n:core.json.song.SongData.NoteData):Float
		return GRID_X + (charColumnOffset.get(n.char) + n.lane) * GRID_SIZE;

	inline function cellY(n:core.json.song.SongData.NoteData):Float
		return n.time * GRID_SIZE / RhythmCore.stepInMs;

	function createSprites(entry:NoteEntry):Void {
		var n = entry.data;
		var x:Float = cellX(n);
		var y:Float = cellY(n);
		var bitmap = noteBitmaps[((n.lane % NOTE_COLORS.length) + NOTE_COLORS.length) % NOTE_COLORS.length];

		var tail = new flixel.FlxSprite(x + GRID_SIZE * 0.35, y + GRID_SIZE * 0.5);
		tail.loadGraphic(bitmap);
		tail.alpha = 0.7;
		tail.active = false;
		noteGroup.add(tail);

		var head = makeArrow(n, x, y);
		if (head == null) {
			head = new flixel.FlxSprite(x + 2, y + 2);
			head.loadGraphic(bitmap);
		}
		head.active = false;
		noteGroup.add(head);

		entry.head = head;
		entry.tail = tail;
		updateTail(entry);
		refreshTypeMark(entry);

		if (selected.contains(entry))
			showMark(entry);
	}

	function destroySprites(entry:NoteEntry):Void {
		for (spr in [entry.head, entry.tail, entry.mark, entry.typeMark]) {
			if (spr == null)
				continue;
			noteGroup.remove(spr, true);
			spr.destroy();
		}
		entry.mark = null;
		entry.typeMark = null;
	}

	function placeEntry(entry:NoteEntry):Void {
		var x:Float = cellX(entry.data);
		var y:Float = cellY(entry.data);

		entry.head.setPosition(x + (GRID_SIZE - entry.head.width) * 0.5, y + (GRID_SIZE - entry.head.height) * 0.5);
		entry.tail.setPosition(x + GRID_SIZE * 0.35, y + GRID_SIZE * 0.5);
		if (entry.mark != null)
			entry.mark.setPosition(x, y);
		refreshTypeMark(entry);
	}

	function updateTail(entry:NoteEntry):Void {
		var len:Float = entry.data.length;
		entry.tail.visible = len > 0;
		if (len <= 0)
			return;

		entry.tail.setGraphicSize(Std.int(GRID_SIZE * 0.3), Std.int(Math.max(1, len * GRID_SIZE / RhythmCore.stepInMs)));
		entry.tail.updateHitbox();
	}

	function copyEvent(e:core.json.song.SongData.EventsData):core.json.song.SongData.EventsData {
		var a:Dynamic = e.arguments;
		var args:Dynamic = null;
		if (a != null)
			args = Std.isOfType(a, Array) ? (cast a : Array<Dynamic>).copy() : Reflect.copy(a);
		return {name: e.name, time: e.time, arguments: args};
	}

	function snapshot():ChartSnapshot {
		return {
			notes: [for (n in SONG.songData.notes) Reflect.copy(n)],
			events: [for (e in SONG.songData.gameplay.events) copyEvent(e)]
		};
	}

	function pushUndo(?snap:ChartSnapshot):Void {
		previewDirty = true;
		undoStack.push(snap != null ? snap : snapshot());
		if (undoStack.length > MAX_UNDO)
			undoStack.shift();
		redoStack = [];
	}

	function restoreSnapshot(snap:ChartSnapshot):Void {
		closePanel();
		clearSelection();

		for (e in noteEntries.copy())
			destroySprites(e);
		noteEntries = [];

		for (e in eventEntries.copy())
			destroyEventSprites(e);
		eventEntries = [];

		SONG.songData.notes = [for (n in snap.notes) Reflect.copy(n)];
		for (n in SONG.songData.notes)
			addNoteSprites(n);

		SONG.songData.gameplay.events = [for (e in snap.events) copyEvent(e)];
		for (e in SONG.songData.gameplay.events)
			addEventSprite(e);

		prepareSinging();
		markDirty();
	}

	function undo():Void {
		if (undoStack.length == 0) {
			setStatus('Nothing to undo.', 0xFFDDDDDD);
			return;
		}
		redoStack.push(snapshot());
		restoreSnapshot(undoStack.pop());
		setStatus('Undo (${undoStack.length} left)', 0xFFDDDDDD);
	}

	function redo():Void {
		if (redoStack.length == 0) {
			setStatus('Nothing to redo.', 0xFFDDDDDD);
			return;
		}
		undoStack.push(snapshot());
		restoreSnapshot(redoStack.pop());
		setStatus('Redo (${redoStack.length} left)', 0xFFDDDDDD);
	}

	function removeEntry(entry:NoteEntry, refresh:Bool = true):Void {
		selected.remove(entry);
		SONG.songData.notes.remove(entry.data);
		noteEntries.remove(entry);
		destroySprites(entry);

		if (refresh)
			prepareSinging();
	}

	function showMark(entry:NoteEntry):Void {
		var x:Float = cellX(entry.data);
		var y:Float = cellY(entry.data);

		if (entry.mark == null) {
			entry.mark = new flixel.FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, 0x66FFFF00);
			entry.mark.active = false;
			noteGroup.add(entry.mark);
		}

		entry.mark.setPosition(x, y);
		entry.mark.visible = true;
	}

	function selectEntry(entry:NoteEntry):Void {
		if (selected.contains(entry))
			return;
		selected.push(entry);
		showMark(entry);
	}

	function deselectEntry(entry:NoteEntry):Void {
		selected.remove(entry);
		if (entry.mark != null)
			entry.mark.visible = false;
	}

	function clearSelection():Void {
		for (e in selected) {
			if (e.mark != null)
				e.mark.visible = false;
		}
		selected = [];
	}

	function selectAll():Void {
		for (e in noteEntries)
			selectEntry(e);
	}

	function deleteSelected():Void {
		if (selected.length == 0)
			return;

		pushUndo();
		for (e in selected.copy())
			removeEntry(e, false);

		prepareSinging();
		markDirty();
		FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'), 0.5);
	}

	function updateBoxSelection(x0:Float, y0:Float, x1:Float, y1:Float):Void {
		var left:Float = Math.min(x0, x1);
		var right:Float = Math.max(x0, x1);
		var top:Float = Math.min(y0, y1);
		var bottom:Float = Math.max(y0, y1);

		boxSprite.setPosition(left, top);
		boxSprite.setGraphicSize(Std.int(Math.max(1, right - left)), Std.int(Math.max(1, bottom - top)));
		boxSprite.updateHitbox();

		clearSelection();
		for (e in boxBase)
			selectEntry(e);

		for (e in noteEntries) {
			var x:Float = cellX(e.data);
			var y:Float = cellY(e.data);

			if (x < right && x + GRID_SIZE > left && y < bottom && y + GRID_SIZE > top)
				selectEntry(e);
		}
	}

	function startMove(column:Int, row:Float):Void {
		moveSnapshot = snapshot();
		moveOrigins = [
			for (e in selected)
				{
					entry: e,
					col: charColumnOffset.get(e.data.char) + e.data.lane,
					time: e.data.time
				}
		];
		moveAnchorCol = column;
		moveAnchorRow = row;
		moveDeltaCol = 0;
		moveDeltaRows = 0;
	}

	function applyMove(dcol:Int, drows:Float):Void {
		var minCol:Int = 999999;
		var maxCol:Int = -1;
		var minRow:Float = 1e9;
		var maxEndRow:Float = -1;

		for (o in moveOrigins) {
			minCol = Std.int(Math.min(minCol, o.col));
			maxCol = Std.int(Math.max(maxCol, o.col));
			minRow = Math.min(minRow, o.time / RhythmCore.stepInMs);
			maxEndRow = Math.max(maxEndRow, (o.time + o.entry.data.length) / RhythmCore.stepInMs);
		}

		dcol = Std.int(Math.max(-minCol, Math.min(dcol, columnOwners.length - 1 - maxCol)));
		drows = Math.max(-minRow, Math.min(drows, totalSteps - 1 - maxEndRow));

		if (dcol == moveDeltaCol && Math.abs(drows - moveDeltaRows) < 0.0001)
			return;

		var columnChanged:Bool = dcol != moveDeltaCol;
		moveDeltaCol = dcol;
		moveDeltaRows = drows;

		for (o in moveOrigins) {
			var owner = columnOwners[o.col + dcol];
			o.entry.data.char = owner.char;
			o.entry.data.lane = owner.lane;
			o.entry.data.time = o.time + drows * RhythmCore.stepInMs;

			if (columnChanged) {
				destroySprites(o.entry);
				createSprites(o.entry);
			} else
				placeEntry(o.entry);
		}
	}

	function finishMove():Void {
		var moved:Bool = moveDeltaCol != 0 || Math.abs(moveDeltaRows) > 0.0001;
		moveOrigins = null;

		if (moved) {
			pushUndo(moveSnapshot);
			prepareSinging();
			markDirty();
		}
		moveSnapshot = null;
	}

	function nudgeSelection(dcol:Int, drows:Float):Void {
		startMove(0, 0);
		applyMove(dcol, drows);
		finishMove();
	}

	function findEntry(column:Int, worldY:Float, includeBody:Bool):NoteEntry {
		var owner = columnOwners[column];
		var mouseMs:Float = worldY / GRID_SIZE * RhythmCore.stepInMs;

		var best:NoteEntry = null;
		var bestDistance:Float = 1e9;
		for (e in noteEntries) {
			if (e.data.char != owner.char || e.data.lane != owner.lane)
				continue;

			var top:Float = cellY(e.data);
			if (worldY >= top && worldY < top + GRID_SIZE) {
				var distance:Float = Math.abs(worldY - (top + GRID_SIZE * 0.5));
				if (distance < bestDistance) {
					best = e;
					bestDistance = distance;
				}
			}
		}
		if (best != null)
			return best;

		if (includeBody) {
			for (e in noteEntries) {
				if (e.data.char != owner.char || e.data.lane != owner.lane)
					continue;

				var len:Float = e.data.length;
				if (len > 0 && mouseMs >= e.data.time && mouseMs <= e.data.time + len)
					return e;
			}
		}

		return null;
	}

	function updateEditing():Void {
		var p = FlxG.mouse.getWorldPosition(camEditor, mousePoint);
		var column:Int = Math.floor((p.x - GRID_X) / GRID_SIZE);
		var step:Int = Math.floor(p.y / GRID_SIZE);
		var row:Float = snapRow(p.y);
		var inRows:Bool = step >= 0 && step < totalSteps;
		var inGrid:Bool = column >= 0 && column < columnOwners.length && inRows;
		var inEvents:Bool = column == columnOwners.length && inRows;

		if (SONG.songData == null)
			return;

		if (dragEntry == null && moveOrigins == null && !boxActive) {
			var modifier:Bool = FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.WINDOWS;

			if (modifier) {
				if (FlxG.keys.justPressed.A)
					selectAll();

				if (FlxG.keys.justPressed.C)
					copySelection();

				if (FlxG.keys.justPressed.X) {
					copySelection();
					deleteSelected();
					return;
				}

				if (FlxG.keys.justPressed.V) {
					pasteClipboard();
					return;
				}

				if (FlxG.keys.justPressed.Z) {
					if (FlxG.keys.pressed.SHIFT)
						redo();
					else
						undo();
					return;
				}

				if (FlxG.keys.justPressed.Y) {
					redo();
					return;
				}
			} else if (FlxG.keys.justPressed.T) {
				if (FlxG.keys.pressed.SHIFT)
					askNewType();
				else
					cycleType(1);
			}

			if (selected.length > 0) {
				if (FlxG.keys.justPressed.DELETE || FlxG.keys.justPressed.BACKSPACE) {
					deleteSelected();
					return;
				}

				if (FlxG.keys.justPressed.UP)
					nudgeSelection(0, -snapRows());
				if (FlxG.keys.justPressed.DOWN)
					nudgeSelection(0, snapRows());
				if (FlxG.keys.justPressed.LEFT)
					nudgeSelection(-1, 0);
				if (FlxG.keys.justPressed.RIGHT)
					nudgeSelection(1, 0);
			}
		}

		if (dragEntry != null) {
			if (FlxG.mouse.pressed) {
				var rows:Float = Math.max(0, Math.min(row, totalSteps - 1) - dragStartRow);
				dragEntry.data.length = rows * RhythmCore.stepInMs;
				updateTail(dragEntry);
			}

			if (FlxG.mouse.justReleased) {
				dragEntry = null;
				prepareSinging();
				markDirty();
			}

			hoverBox.visible = false;
			return;
		}

		if (moveOrigins != null) {
			if (FlxG.mouse.pressed)
				applyMove(column - moveAnchorCol, row - moveAnchorRow);

			if (FlxG.mouse.justReleased)
				finishMove();

			hoverBox.visible = false;
			return;
		}

		if (boxActive) {
			if (FlxG.mouse.pressed)
				updateBoxSelection(boxStartX, boxStartY, p.x, p.y);

			if (FlxG.mouse.justReleased) {
				boxActive = false;
				boxSprite.visible = false;
			}

			hoverBox.visible = false;
			return;
		}

		if (inEvents) {
			showHover(column, row);

			if (FlxG.mouse.justPressedRight) {
				var found = findEvent(p.y);
				if (found != null) {
					pushUndo();
					removeEvent(found);
					markDirty();
					FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'), 0.5);
				}
				return;
			}

			if (FlxG.mouse.justPressed) {
				var found = findEvent(p.y);
				if (found == null) {
					pushUndo();
					found = createEvent(row);
					markDirty();
					FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'), 0.6);
				}
				openEventPanel(found);
			}
			return;
		}

		hoverBox.visible = inGrid;
		if (!inGrid)
			return;

		showHover(column, row);

		if (FlxG.mouse.justPressedRight) {
			var found = findEntry(column, p.y, true);
			if (found != null) {
				if (selected.contains(found) && selected.length > 1) {
					deleteSelected();
				} else {
					pushUndo();
					removeEntry(found);
					markDirty();
					FlxG.sound.play(Paths.getPath('menus/cancelMenu', 'sound'), 0.5);
				}
			}
			return;
		}

		if (!FlxG.mouse.justPressed)
			return;

		var existing = findEntry(column, p.y, false);

		if (FlxG.keys.pressed.SHIFT) {
			if (existing != null) {
				if (selected.contains(existing))
					deselectEntry(existing);
				else
					selectEntry(existing);
			} else {
				boxActive = true;
				boxStartX = p.x;
				boxStartY = p.y;
				boxBase = selected.copy();
				boxSprite.visible = true;
				updateBoxSelection(p.x, p.y, p.x, p.y);
			}
			return;
		}

		if (existing != null) {
			if (!selected.contains(existing)) {
				clearSelection();
				selectEntry(existing);
			}
			startMove(column, row);
			return;
		}

		clearSelection();

		var owner = columnOwners[column];
		var note:core.json.song.SongData.NoteData = {
			char: owner.char,
			lane: owner.lane,
			time: rowTime(row),
			type: noteType,
			length: 0
		};

		pushUndo();
		SONG.songData.notes.push(note);
		dragEntry = addNoteSprites(note);
		dragStartRow = row;
		prepareSinging();
		markDirty();
		FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'), 0.6);
	}

	function showHover(column:Int, row:Float):Void {
		hoverBox.visible = true;
		hoverBox.setGraphicSize(GRID_SIZE, Std.int(Math.max(2, snapRows() * GRID_SIZE)));
		hoverBox.updateHitbox();
		hoverBox.setPosition(GRID_X + column * GRID_SIZE, row * GRID_SIZE);
	}

	function layoutRail():Void {
		var freeX:Float = GRID_X + (COLUMNS + 1) * GRID_SIZE + 20;
		var freeW:Float = FlxG.width - freeX;
		railW = Std.int(freeW * PREVIEW_SCALE);
		railX = Std.int(freeX + (freeW - railW) * 0.5);
	}

	function buildGameplayView():Void {
		layoutRail();
		var viewW:Int = railW;
		var viewH:Int = Std.int(viewW * FlxG.height / FlxG.width);
		var viewX:Int = Std.int(railX);
		var viewY:Int = Std.int(Math.max(0, Math.min(PREVIEW_TOP, FlxG.height - viewH)));

		previewW = viewW;
		previewH = viewH;

		camGameplay = new Camera(viewX, viewY, viewW, viewH);
		camGameplay.bgColor = 0xFF000000;
		FlxG.cameras.add(camGameplay, false);

		FlxG.cameras.remove(camHud, false);
		FlxG.cameras.add(camHud, false);

		director = new PreviewEvents(c -> {
			assignCamera(c, camGameplay);
			for (layer in c.layers)
				layer.cameras = [camGameplay];
			if (stage != null) {
				stage.applyCharProps(c, c.id);
				var camPos = stage.charProps.get(c.id)?.camPos;
				if (camPos != null) {
					c.cameraOffset.x += camPos[0];
					c.cameraOffset.y += camPos[1];
				}
			}

			c.dance();
		});

		for (part in EditorWidgets.frame(viewX, viewY, viewW, viewH, 2, EditorWidgets.CARD_BORDER, camHud))
			add(part);

		previewLabel = new flixel.text.FlxText(viewX, viewY + viewH + 8, viewW, '', 12);
		previewLabel.setFormat(null, 12, 0xFFC8C8D8, LEFT, OUTLINE, FlxColor.BLACK);
		previewLabel.scrollFactor.set(0, 0);
		previewLabel.cameras = [camHud];
		add(previewLabel);

		buildStage();
	}

	function resyncPreview():Void {
		if (director == null || chars == null)
			return;
		director.reset(SONG.songData?.gameplay?.events ?? [], RhythmCore.songPosition);
	}

	function buildStage():Void {
		var viewW:Int = previewW;
		var viewH:Int = previewH;

		try {
			var stageName:String = SONG.stage;
			if (stageName == null || !Paths.exists('data/stages/$stageName.json'))
				stageName = ChartDefaults.FALLBACK_STAGE;

			stage = new game.objects.sprites.Stage(stageName);
			add(stage);

			if (!stage.members.contains(stage.charLayer))
				stage.add(stage.charLayer);

			chars = new game.controllers.CharacterController();
			stage.charLayer.add(chars);

			for (data in SONG.chars) {
				chars.loadCharacter(data.id, data.name, data.role, stage.charLayer, null);
				stage.applyCharProps(chars.get(data.id), data.id);
			}

			chars.danceAll();

			assignCamera(stage, camGameplay);

			var fit:Float = Math.min(viewW / FlxG.width, viewH / FlxG.height);
			camGameplay.zoom = stage.defaultZoom * fit;

			var gf:game.objects.sprites.Character = null;
			var gfId:String = null;
			for (data in SONG.chars) {
				if (game.controllers.CharacterController.namesGf.contains(data.role)) {
					gf = cast(chars.get(data.id), game.objects.sprites.Character);
					gfId = data.id;
					break;
				}
			}

			if (gf != null) {
				var pos = gf.getCamPosition();

				var stageProps = stage.charProps.get(gfId);
				if (stageProps?.camPos != null) {
					pos.x += stageProps.camPos[0];
					pos.y += stageProps.camPos[1];
				}

				camGameplay.scroll.set(pos.x - viewW * 0.5, pos.y - viewH * 0.5);
			} else {
				var sumX:Float = 0;
				var sumY:Float = 0;
				var count:Int = 0;
				for (data in SONG.chars) {
					var char = cast(chars.get(data.id), game.objects.sprites.Character);
					if (char == null)
						continue;
					var mid = char.getMidpoint();
					sumX += mid.x;
					sumY += mid.y;
					count++;
					mid.put();
				}

				if (count > 0)
					camGameplay.scroll.set(sumX / count - viewW * 0.5, sumY / count - viewH * 0.5);
			}

			if (director != null) {
				director.attach(camGameplay, chars, SONG.chars, SONG.songData?.meta?.speed ?? 1, SONG.songData?.meta?.bpm ?? 120);
				resyncPreview();
			}
		} catch (e:Dynamic) {
			Trace.traceOnce('GameplayEditor: could not build the stage preview: $e', true);
			startupNotes.push('The stage preview could not be built: $e');
		}
	}

	function reloadPreview():Void {
		safe('gameplay preview', () -> {
			if (stage != null) {
				remove(stage, true);
				stage.destroy();
			}
			stage = null;
			chars = null;

			if (headerGroup != null) {
				remove(headerGroup, true);
				headerGroup.destroy();
				headerGroup = null;
			}

			buildStage();
			buildHeaders();
		});
		showStartupNotes();
	}

	function prepareSinging():Void {
		if (SONG.songData == null)
			return;

		SONG.songData.notes.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
		sortedNotes = SONG.songData.notes.copy();
		sustainNotes = sortedNotes.filter(n -> n.length > 0);
		seekNotes();
	}

	function seekNotes():Void {
		noteIndex = 0;
		while (noteIndex < sortedNotes.length && sortedNotes[noteIndex].time < RhythmCore.songPosition)
			noteIndex++;

		resyncPreview();
	}

	function singNote(n:core.json.song.SongData.NoteData):Void {
		if (chars == null)
			return;

		var char = cast(chars.get(n.char), game.objects.sprites.Character);
		if (char == null)
			return;

		var anim = game.objects.sprites.Character.getCharAnim(n.lane);
		if (!char.existsAnim(anim))
			return;

		if (director != null)
			director.noteSung(char);

		char.playAnim(anim, true);
		char.singCountTime = 0;
		char.isSing = true;
		char.isMiss = false;
	}

	function updateSinging():Void {
		var pos:Float = RhythmCore.songPosition;

		var hit:Bool = false;
		while (noteIndex < sortedNotes.length && sortedNotes[noteIndex].time <= pos) {
			singNote(sortedNotes[noteIndex]);
			noteIndex++;
			hit = true;
		}

		if (hit && hitsounds)
			FlxG.sound.play(Paths.getPath('gameplay/hitsounds/hit-1', 'sound'), 0.6);

		for (n in sustainNotes) {
			if (pos < n.time || pos > n.time + n.length)
				continue;

			var char = chars != null ? cast(chars.get(n.char), game.objects.sprites.Character) : null;
			if (char != null) {
				char.singCountTime = 0;
				char.isSing = true;
			}
		}
	}

	override public function beatHit(beat:Float):Void {
		super.beatHit(beat);

		if (!isPlaying)
			return;

		if (chars != null)
			chars.danceAll();

		if (metronome)
			FlxG.sound.play(Paths.getPath('menus/scrollMenu', 'sound'), 0.4);
	}

	function assignCamera(obj:flixel.FlxBasic, cam:flixel.FlxCamera):Void {
		if (obj == null)
			return;

		obj.cameras = [cam];

		if (Std.isOfType(obj, flixel.group.FlxGroup.FlxTypedGroup)) {
			var group:flixel.group.FlxGroup = cast obj;
			for (member in group.members)
				assignCamera(member, cam);
		}
	}

	function buildHeaders():Void {
		headerGroup = new flixel.group.FlxGroup();
		add(headerGroup);

		for (i in 0...columnLabels.length) {
			var label = columnLabels[i];
			var width:Int = label.lanes * GRID_SIZE;
			var x:Float = GRID_X + label.column * GRID_SIZE;

			var strip = new flixel.FlxSprite(x, 0).makeGraphic(width, HEADER_H, HEADER_COLOR);
			strip.scrollFactor.set(0, 0);
			strip.cameras = [camHud];
			headerGroup.add(strip);

			var lines:Array<Float> = i == columnLabels.length - 1 ? [x - 1, x + width - 1] : [x - 1];
			for (lineX in lines) {
				var line = new flixel.FlxSprite(lineX, 0).makeGraphic(2, HEADER_H, HEADER_LINE_COLOR);
				line.scrollFactor.set(0, 0);
				line.cameras = [camHud];
				headerGroup.add(line);
			}

			var isPlayer:Bool = game.controllers.CharacterController.namesPlayer.contains(label.role);

			var charObj = chars != null ? cast(chars.get(label.id), game.objects.sprites.Character) : null;
			if (charObj != null) {
				try {
					var icon = new game.objects.sprites.Icon(isPlayer, charObj.characterData);
					var fit:Float = ICON_SIZE / Math.max(1, icon.frameHeight);
					icon.scale.set(fit, fit);
					icon.updateHitbox();
					icon.setPosition(x + (width - icon.width) * 0.5, 2);
					icon.scrollFactor.set(0, 0);
					icon.active = false;
					icon.cameras = [camHud];
					headerGroup.add(icon);
				} catch (e:Dynamic) {
					Trace.traceOnce('GameplayEditor: no icon for "${label.id}": $e', true);
				}
			}

			var roleTxt = new flixel.text.FlxText(x, ICON_SIZE + 8, width, roleName(label.role), 12);
			roleTxt.setFormat(null, 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			roleTxt.scrollFactor.set(0, 0);
			roleTxt.cameras = [camHud];
			headerGroup.add(roleTxt);
		}

		var eventX:Float = GRID_X + COLUMNS * GRID_SIZE;
		var eventStrip = new flixel.FlxSprite(eventX, 0).makeGraphic(GRID_SIZE, HEADER_H, HEADER_COLOR);
		eventStrip.scrollFactor.set(0, 0);
		eventStrip.cameras = [camHud];
		headerGroup.add(eventStrip);

		var eventLine = new flixel.FlxSprite(eventX + GRID_SIZE - 1, 0).makeGraphic(2, HEADER_H, HEADER_LINE_COLOR);
		eventLine.scrollFactor.set(0, 0);
		eventLine.cameras = [camHud];
		headerGroup.add(eventLine);

		var eventTxt = new flixel.text.FlxText(eventX - 16, ICON_SIZE + 10, GRID_SIZE + 32, 'EVT', 10);
		eventTxt.setFormat(null, 10, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		eventTxt.scrollFactor.set(0, 0);
		eventTxt.cameras = [camHud];
		headerGroup.add(eventTxt);
	}

	function roleName(role:String):String {
		if (game.controllers.CharacterController.namesPlayer.contains(role))
			return 'PLAYER';
		if (game.controllers.CharacterController.namesOpponent.contains(role))
			return 'OPPONENT';
		if (game.controllers.CharacterController.namesGf.contains(role))
			return 'GIRLFRIEND';
		return role.toUpperCase();
	}

	function setStatus(text:String, color:Int):Void {
		if (statusText == null)
			return;
		statusText.text = text;
		statusText.color = color;
	}

	function markDirty():Void {
		dirty = true;
		leaveArmed = false;
		setStatus('Unsaved changes (Ctrl/Cmd+S to save)', 0xFFFFCC33);
	}

	function pickDiffName():String {
		if (diff != null)
			return diff;

		var list = core.rhythm.DiffsUtils.difficulties;
		var index = states.menus.FreeplayState.curDiff;
		return (index >= 0 && index < list.length) ? list[index] : 'normal';
	}

	function saveChart():Void {
		if (SONG.songData == null) {
			setStatus('Nothing to save: this song has no chart data.', 0xFFFF5555);
			return;
		}

		var folderPath:String = 'songs/$songDir/charts';

		var osuPath = core.assets.Library.findLib('$folderPath/$chartDiff.osu');
		if (osuPath != null && sys.FileSystem.exists(osuPath)) {
			setStatus('This chart is an .osu file. Saving to .osu is not supported yet.', 0xFFFF5555);
			return;
		}

		var path = core.assets.Library.findLib('$folderPath/$chartDiff.json');
		var created:Bool = path == null || !sys.FileSystem.exists(path);
		if (created)
			path = ChartDefaults.newChartPath(songDir, chartDiff);

		try {
			if (created)
				ChartDefaults.makeDirs(haxe.io.Path.directory(path));

			SONG.songData.notes.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
			SONG.songData.gameplay.events.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
			sys.io.File.saveContent(path, haxe.Json.stringify(SONG.songData, null, '\t'));

			dirty = false;
			leaveArmed = false;

			if (created) {
				isNewChart = false;
				core.rhythm.DiffsUtils.getDifficulty(songDir);
				var index = core.rhythm.DiffsUtils.getDiffIndex(chartDiff);
				if (index >= 0)
					states.menus.FreeplayState.curDiff = index;
				setStatus('Chart created: $path', 0xFF66DD66);
			} else
				setStatus('Saved: $path', 0xFF66DD66);
		} catch (e:Dynamic) {
			setStatus('Could not save: $e', 0xFFFF5555);
		}
	}

	override public function destroy():Void {
		prompt.close(false);
		if (director != null)
			director.destroy();
		director = null;
		SaveData.data.logInScreen = previousLogInScreen;
		utils.Trace.updateVisibility();
		if (core.ui.FPSCounter.instance != null)
			core.ui.FPSCounter.instance.updateVisibility();
		super.destroy();
	}

	function endSong() {
		isPlaying = false;
	}

	override public function update(elapsed:Float) {
		if (!ready) {
			super.update(elapsed);
			if (!acceptOption && Controls.BACK)
				leaveEditor();
			return;
		}

		var keysLocked:Bool = prompt.active || prompt.justClosed;
		prompt.justClosed = false;

		if (isPlaying) {
			if (hasAudio)
				RhythmCore.songPosition = gameAudio.inst.time;
			else
				RhythmCore.songPosition += elapsed * 1000 * SPEEDS[speedIndex];
		}

		if (RhythmCore.songPosition < lastPosition - 1) {
			t.reset();
			seekNotes();
		}
		lastPosition = RhythmCore.songPosition;

		super.update(elapsed);

		if (acceptOption)
			return;

		infoHUD.updateInfoText(RhythmCore.songPosition, RhythmCore.stepInMs, RhythmCore.bpm);

		if (viewToggles != null && FlxG.mouse.justPressed)
			viewToggles.click(FlxG.mouse.viewX, FlxG.mouse.viewY);

		if (director != null) {
			if (!isPlaying && Math.abs(RhythmCore.songPosition - previewLastPos) > 0.5)
				previewDirty = true;

			if (!isPlaying) {
				var signature:String = haxe.Json.stringify(SONG.songData?.gameplay?.events ?? []);
				if (signature != previewSignature) {
					previewSignature = signature;
					previewDirty = true;
				}
			}
			previewLastPos = RhythmCore.songPosition;

			if (previewDirty && !isPlaying) {
				previewDirty = false;
				resyncPreview();
			}

			if (isPlaying)
				director.advance(RhythmCore.songPosition);
			director.update(elapsed);

			if (previewLabel != null) {
				previewLabel.text = director.describe();
			}
		}

		if (prompt.active && panelMode == '')
			setStatus('${prompt.label}: ${prompt.text}_    (Enter: accept · Esc: cancel)', 0xFFFFFFFF);

		if (!keysLocked && panelMode == '')
			updateTools();

		if (!keysLocked && FlxG.keys.justPressed.SPACE) {
			isPlaying = !isPlaying;
			if (isPlaying) {
				seekNotes();
				t.reset();
				if (hasAudio) {
					gameAudio.setTime(RhythmCore.songPosition);
					gameAudio.playAll();
					applySpeed();
					gameAudio.resyncVocals();
				}
			} else if (hasAudio) {
				RhythmCore.pause(gameAudio);
				gameAudio.pauseAll();
			}
		}

		var totalMs:Float = songLength;

		if (FlxG.mouse.wheel != 0 && !isPlaying) {
			var ms:Float = FlxG.keys.pressed.SHIFT ? SCROLL_MS * 4 : SCROLL_MS;
			var delta:Float = -FlxG.mouse.wheel * ms;

			RhythmCore.songPosition = Math.max(0, Math.min(RhythmCore.songPosition + delta, totalMs));

			if (hasAudio)
				gameAudio.setTime(RhythmCore.songPosition);
			t.reset();
		}

		if (isPlaying && totalMs > 0 && RhythmCore.songPosition >= totalMs) {
			RhythmCore.songPosition = totalMs;
			isPlaying = false;
		}

		var panelWasOpen:Bool = panelMode != '';

		updateSinging();

		if (panelMode != '') {
			hoverBox.visible = false;
			updatePanel(keysLocked);
		} else if (isPlaying) {
			hoverBox.visible = false;
		} else if (keysLocked) {
			hoverBox.visible = false;
		} else if (FlxG.keys.justPressed.TAB && dragEntry == null && moveOrigins == null && !boxActive) {
			openPanel('setup');
		} else {
			updateEditing();
		}

		camEditor.scroll.y = RhythmCore.songPosition / RhythmCore.stepInMs * GRID_SIZE - FlxG.height * 0.5;

		if (!keysLocked && (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.WINDOWS) && FlxG.keys.justPressed.S)
			saveChart();

		if (!keysLocked && Controls.BACK && !panelWasOpen) {
			if (dirty && !leaveArmed) {
				leaveArmed = true;
				setStatus('Unsaved changes! Press back again to leave without saving, or Ctrl/Cmd+S to save.', 0xFFFF5555);
				return;
			}

			leaveEditor();
		}
	}

	function leaveEditor():Void {
		acceptOption = true;
		gameAudio.stopAll();

		if (chartOnDisk()) {
			var index = core.rhythm.DiffsUtils.getDiffIndex(chartDiff);
			if (index < 0)
				index = states.menus.FreeplayState.curDiff;
			MusicBeatState.switchState(() -> new game.PlayState(songDir, index));
		} else
			MusicBeatState.switchState(() -> new states.menus.FreeplayState());
	}

	function updateTools():Void {
		if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.WINDOWS)
			return;

		if (FlxG.keys.justPressed.Q)
			changeSnap(-1);
		if (FlxG.keys.justPressed.E)
			changeSnap(1);

		if (FlxG.keys.justPressed.M) {
			metronome = !metronome;
			refreshTools();
		}
		if (FlxG.keys.justPressed.H) {
			hitsounds = !hitsounds;
			refreshTools();
		}

		if (viewToggles != null) {
			var keys = [FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR];
			for (i in 0...keys.length) {
				if (keys[i]) {
					viewToggles.set(i, !viewToggles.get(i));
					applyView();
				}
			}
			if (FlxG.keys.justPressed.F1) {
				viewToggles.set(0, !viewToggles.get(0));
				applyView();
			}
		}

		if (FlxG.keys.justPressed.F && director != null) {
			director.follow = !director.follow;
			if (director.follow)
				director.snapNow();
			refreshTools();
		}

		if (FlxG.keys.justPressed.COMMA)
			changeSpeed(-1);
		if (FlxG.keys.justPressed.PERIOD)
			changeSpeed(1);
	}

	function changeSnap(dir:Int):Void {
		snapIndex = Std.int(Math.max(0, Math.min(snapIndex + dir, SNAPS.length - 1)));
		refreshTools();
	}

	function changeSpeed(dir:Int):Void {
		speedIndex = Std.int(Math.max(0, Math.min(speedIndex + dir, SPEEDS.length - 1)));
		applySpeed();
		refreshTools();
	}

	function applySpeed():Void {
		var rate:Float = SPEEDS[speedIndex];
		gameAudio.forEachAlive(function(s:flixel.sound.FlxSound) {
			if (s != null)
				s.pitch = rate;
		});
	}

	function applyView():Void {
		var showHelp:Bool = viewState[0];
		if (helpBar != null)
			helpBar.visible = showHelp;
		if (helpText != null)
			helpText.visible = showHelp;
		if (helpTopLine != null)
			helpTopLine.visible = showHelp;
		if (infoHUD != null)
			infoHUD.visible = viewState[1];
		if (toolText != null)
			toolText.visible = viewState[2];
		if (toolCard != null)
			toolCard.visible = viewState[2];
		if (previewLabel != null)
			previewLabel.visible = viewState[3];
	}

	function refreshTools():Void {
		if (toolText == null)
			return;

		var follow:Bool = director != null && director.follow;
		var cap = new flixel.text.FlxText.FlxTextFormatMarkerPair(new flixel.text.FlxText.FlxTextFormat(EditorWidgets.MUTED), '<c>');
		var on = new flixel.text.FlxText.FlxTextFormatMarkerPair(new flixel.text.FlxText.FlxTextFormat(EditorWidgets.GOOD), '<g>');
		var off = new flixel.text.FlxText.FlxTextFormatMarkerPair(new flixel.text.FlxText.FlxTextFormat(EditorWidgets.MUTED), '<d>');
		toolText.applyMarkup('<c>SNAP<c> 1/${SNAPS[snapIndex]}    <c>TYPE<c> $noteType    <c>SPEED<c> x${SPEEDS[speedIndex]}\n'
			+ '<c>METRONOME<c> ${metronome ? "<g>on<g>" : "<d>off<d>"}    <c>HIT SOUNDS<c> ${hitsounds ? "<g>on<g>" : "<d>off<d>"}    <c>CAMERA FOLLOW<c> ${follow ? "<g>on<g>" : "<d>off<d>"}',
			[cap, on, off]);
	}

	function cycleName(list:Array<String>, current:String, dir:Int):String {
		if (list.length == 0)
			return current;

		var i:Int = list.indexOf(current);
		if (i < 0)
			return list[dir > 0 ? 0 : list.length - 1];
		return list[((i + dir) % list.length + list.length) % list.length];
	}

	function typeList():Array<String> {
		var list:Array<String> = ['normal'];
		for (n in SONG.songData.notes) {
			if (n.type != null && !list.contains(n.type))
				list.push(n.type);
		}
		for (t in customTypes) {
			if (!list.contains(t))
				list.push(t);
		}
		if (!list.contains(noteType))
			list.push(noteType);
		return list;
	}

	function cycleType(dir:Int):Void {
		noteType = cycleName(typeList(), noteType, dir);
		applyTypeToSelection();
		refreshTools();
	}

	function applyTypeToSelection():Void {
		if (selected.length == 0)
			return;

		pushUndo();
		for (e in selected) {
			e.data.type = noteType;
			refreshTypeMark(e);
		}
		markDirty();
	}

	function askNewType():Void {
		prompt.open('New note type', '', function(name:String) {
			name = StringTools.trim(name);
			if (name == '')
				return;
			customTypes.push(name);
			noteType = name;
			applyTypeToSelection();
			refreshTools();
		});
	}

	function refreshTypeMark(entry:NoteEntry):Void {
		var typed:Bool = entry.data.type != null && entry.data.type != 'normal';

		if (typed && entry.typeMark == null) {
			entry.typeMark = new flixel.FlxSprite().makeGraphic(10, 10, 0xFFFF66FF);
			entry.typeMark.active = false;
			noteGroup.add(entry.typeMark);
		} else if (!typed && entry.typeMark != null) {
			noteGroup.remove(entry.typeMark, true);
			entry.typeMark.destroy();
			entry.typeMark = null;
		}

		if (entry.typeMark != null)
			entry.typeMark.setPosition(cellX(entry.data) + GRID_SIZE - 12, cellY(entry.data) + 2);
	}

	function copySelection():Void {
		if (selected.length == 0)
			return;

		var firstTime:Float = 1e12;
		for (e in selected)
			firstTime = Math.min(firstTime, e.data.time);

		clipboard = [
			for (e in selected)
				{
					col: charColumnOffset.get(e.data.char) + e.data.lane,
					dt: e.data.time - firstTime,
					data: Reflect.copy(e.data)
				}
		];
		setStatus('Copied ${clipboard.length} notes', 0xFFDDDDDD);
	}

	function pasteClipboard():Void {
		if (clipboard.length == 0) {
			setStatus('Nothing to paste: select notes and press Ctrl/Cmd+C first.', 0xFFDDDDDD);
			return;
		}

		var baseRow:Float = Math.floor(timeRow(RhythmCore.songPosition) / snapRows() + 0.0001) * snapRows();
		var baseTime:Float = rowTime(baseRow);

		pushUndo();
		clearSelection();

		var added:Int = 0;
		for (c in clipboard) {
			if (c.col >= columnOwners.length)
				continue;

			var owner = columnOwners[c.col];
			var note:core.json.song.SongData.NoteData = {
				char: owner.char,
				lane: owner.lane,
				time: baseTime + c.dt,
				type: c.data.type,
				length: c.data.length
			};

			if (timeRow(note.time + note.length) > totalSteps - 1)
				continue;

			SONG.songData.notes.push(note);
			var entry = addNoteSprites(note);
			if (entry != null) {
				selectEntry(entry);
				added++;
			}
		}

		prepareSinging();
		markDirty();
		setStatus('Pasted $added notes', 0xFFDDDDDD);
	}

	function charIds():Array<String> {
		return [for (c in SONG.chars) c.id];
	}

	function buildEvents():Void {
		eventGroup = new flixel.group.FlxGroup();
		eventGroup.active = false;
		add(eventGroup);

		for (ev in SONG.songData.gameplay.events)
			addEventSprite(ev);
	}

	function addEventSprite(data:core.json.song.SongData.EventsData):EventEntry {
		var box = new flixel.FlxSprite().makeGraphic(GRID_SIZE - 4, GRID_SIZE - 4, FlxColor.WHITE);
		box.active = false;
		eventGroup.add(box);

		var label = new flixel.text.FlxText(0, 0, GRID_SIZE, '', 11);
		label.setFormat(null, 11, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		label.active = false;
		eventGroup.add(label);

		var entry:EventEntry = {data: data, box: box, label: label};
		eventEntries.push(entry);
		refreshEvent(entry);
		return entry;
	}

	function destroyEventSprites(entry:EventEntry):Void {
		for (spr in [entry.box, entry.label]) {
			eventGroup.remove(spr, true);
			spr.destroy();
		}
	}

	function refreshEvent(entry:EventEntry):Void {
		var x:Float = GRID_X + columnOwners.length * GRID_SIZE;
		var y:Float = entry.data.time * GRID_SIZE / RhythmCore.stepInMs;

		entry.box.setPosition(x + 2, y + 2);
		entry.box.color = EditorWidgets.eventColor(entry.data.name);

		entry.label.text = EditorWidgets.eventAbbreviation(entry.data.name);
		entry.label.setPosition(x, y + 9);
		entry.label.color = entry == panelEvent ? FlxColor.YELLOW : FlxColor.WHITE;
	}

	function refreshEventMarks():Void {
		for (e in eventEntries)
			refreshEvent(e);
	}

	function findEvent(worldY:Float):EventEntry {
		var best:EventEntry = null;
		var bestDistance:Float = 1e9;
		for (e in eventEntries) {
			var top:Float = e.data.time * GRID_SIZE / RhythmCore.stepInMs;
			if (worldY >= top && worldY < top + GRID_SIZE) {
				var distance:Float = Math.abs(worldY - (top + GRID_SIZE * 0.5));
				if (distance < bestDistance) {
					best = e;
					bestDistance = distance;
				}
			}
		}
		return best;
	}

	function createEvent(row:Float):EventEntry {
		var template = game.controllers.events.EventManager.findSchema(lastEventName) ?? game.controllers.events.EventManager.schemas[0];
		var data:core.json.song.SongData.EventsData = {
			name: template.name,
			time: rowTime(row),
			arguments: game.controllers.events.EventManager.defaultArgs(template, charIds(), SONG.songData.meta.bpm)
		};

		SONG.songData.gameplay.events.push(data);
		return addEventSprite(data);
	}

	function removeEvent(entry:EventEntry):Void {
		if (panelEvent == entry)
			closePanel();

		SONG.songData.gameplay.events.remove(entry.data);
		eventEntries.remove(entry);
		destroyEventSprites(entry);
	}

	function ensureArgs(data:core.json.song.SongData.EventsData):Void {
		if (data.arguments == null || Std.isOfType(data.arguments, Array))
			data.arguments = {};
	}

	function argValue(data:core.json.song.SongData.EventsData, key:String):Dynamic {
		if (data.arguments == null || Std.isOfType(data.arguments, Array))
			return null;
		return Reflect.field(data.arguments, key);
	}

	function applyBpm(bpm:Float):Void {
		if (Math.isNaN(bpm))
			return;

		bpm = Math.round(Math.max(20, Math.min(bpm, 400)) * 100) / 100;
		if (bpm == SONG.songData.meta.bpm)
			return;

		SONG.songData.meta.bpm = bpm;
		SONG.bpmSong = bpm;
		RhythmCore.changeBPM(bpm);
		t.reset();

		buildGrid(songLength);
		for (e in noteEntries) {
			placeEntry(e);
			updateTail(e);
		}
		refreshEventMarks();

		markDirty();
	}

	function setSpeedValue(speed:Float):Void {
		speed = Math.round(Math.max(0.5, Math.min(speed, 6)) * 100) / 100;
		SONG.songData.meta.speed = speed;
		SONG.speed = speed;
		markDirty();
	}

	function openPanel(mode:String):Void {
		panelMode = mode;
		panelRow = 0;
		panelUndoPushed = false;
		refreshPanel();
	}

	function closePanel():Void {
		prompt.close(false);
		panelMode = '';
		panelEvent = null;
		if (panel != null)
			panel.hide();
		refreshEventMarks();
	}

	function openEventPanel(entry:EventEntry):Void {
		panelEvent = entry;
		lastEventName = entry.data.name;
		openPanel('event');
		refreshEventMarks();
	}

	function pushUndoOnce():Void {
		if (panelUndoPushed)
			return;
		panelUndoPushed = true;
		pushUndo();
	}

	function eventFields():Array<game.controllers.events.EventManager.EventField> {
		if (panelEvent == null)
			return [];
		var template = game.controllers.events.EventManager.findSchema(panelEvent.data.name);
		return template != null ? template.fields : [];
	}

	function panelRowCount():Int {
		if (panelMode == 'setup')
			return SONG.chars.length + 3;
		if (panelMode == 'event')
			return 2 + eventFields().length;
		return 1;
	}

	function updatePanel(locked:Bool):Void {
		if (locked) {
			refreshPanel();
			return;
		}

		if (Controls.BACK || FlxG.keys.justPressed.TAB) {
			closePanel();
			return;
		}

		var rows:Int = panelRowCount();
		if (FlxG.keys.justPressed.UP)
			panelRow = (panelRow + rows - 1) % rows;
		if (FlxG.keys.justPressed.DOWN)
			panelRow = (panelRow + 1) % rows;

		if (panelMode == 'event' && panelEvent != null && FlxG.keys.justPressed.DELETE) {
			var entry = panelEvent;
			closePanel();
			pushUndo();
			removeEvent(entry);
			markDirty();
			return;
		}

		var dir:Int = FlxG.keys.justPressed.LEFT ? -1 : (FlxG.keys.justPressed.RIGHT ? 1 : 0);
		if (dir != 0) {
			if (panelMode == 'setup')
				changeSetupRow(dir);
			else
				changeEventRow(dir);
		}

		if (FlxG.keys.justPressed.ENTER)
			editPanelRow();

		refreshPanel();
	}

	function changeSetupRow(dir:Int):Void {
		var big:Bool = FlxG.keys.pressed.SHIFT;
		var chars:Int = SONG.chars.length;

		if (panelRow == 0) {
			var stages = ChartDefaults.listNames('stages');
			if (stages.length == 0)
				return;
			var name = cycleName(stages, SONG.songData.meta.stage, dir);
			SONG.songData.meta.stage = name;
			SONG.stage = name;
			reloadPreview();
			markDirty();
		} else if (panelRow <= chars) {
			var names = ChartDefaults.listNames('characters');
			if (names.length == 0)
				return;
			var data = SONG.chars[panelRow - 1];
			data.name = cycleName(names, data.name, dir);
			reloadPreview();
			markDirty();
		} else if (panelRow == chars + 1) {
			setSpeedValue(SONG.songData.meta.speed + dir * (big ? 1 : 0.1));
		} else {
			applyBpm(SONG.songData.meta.bpm + dir * (big ? 10 : 1));
		}
	}

	function changeEventRow(dir:Int):Void {
		if (panelEvent == null)
			return;

		var big:Bool = FlxG.keys.pressed.SHIFT;
		var data = panelEvent.data;

		if (panelRow == 0) {
			pushUndoOnce();
			var delta:Float = dir * snapRows() * RhythmCore.stepInMs * (big ? 4 : 1);
			data.time = Math.max(0, Math.min(data.time + delta, (totalSteps - 1) * RhythmCore.stepInMs));
		} else if (panelRow == 1) {
			pushUndoOnce();
			data.name = cycleName(game.controllers.events.EventManager.schemaNames(), data.name, dir);
			data.arguments = game.controllers.events.EventManager.defaultArgs(game.controllers.events.EventManager.findSchema(data.name), charIds(),
				SONG.songData.meta.bpm);
			lastEventName = data.name;
		} else {
			var field = eventFields()[panelRow - 2];
			pushUndoOnce();
			ensureArgs(data);

			var current:Dynamic = argValue(data, field.key);
			switch (field.kind) {
				case 'char':
					Reflect.setField(data.arguments, field.key, cycleName(charIds(), Std.string(current), dir));
				case 'charName':
					Reflect.setField(data.arguments, field.key,
						cycleName(ChartDefaults.listNames('characters'), Std.string(current), dir));
				case 'bool':
					Reflect.setField(data.arguments, field.key, current != true);
				case 'float':
					var value:Float = Std.parseFloat(Std.string(current));
					if (Math.isNaN(value))
						value = 0;
					value += dir * (field.step ?? 1) * (big ? 10 : 1);
					if (field.min != null)
						value = Math.max(field.min, value);
					if (field.max != null)
						value = Math.min(field.max, value);
					Reflect.setField(data.arguments, field.key, Math.round(value * 1000) / 1000);
				default:
			}
		}

		refreshEvent(panelEvent);
		markDirty();
	}

	function editPanelRow():Void {
		if (panelMode == 'setup') {
			var chars:Int = SONG.chars.length;

			if (panelRow >= 1 && panelRow <= chars) {
				var index:Int = panelRow - 1;
				prompt.open('Character file', SONG.chars[index].name ?? '', function(text:String) {
					text = StringTools.trim(text);
					if (text == '')
						return;
					SONG.chars[index].name = text;
					reloadPreview();
					markDirty();
				});
			} else if (panelRow == chars + 1) {
				prompt.open('Scroll speed', Std.string(SONG.songData.meta.speed), function(text:String) {
					var value:Float = Std.parseFloat(text);
					if (!Math.isNaN(value))
						setSpeedValue(value);
				});
			} else if (panelRow == chars + 2) {
				prompt.open('BPM', Std.string(SONG.songData.meta.bpm), function(text:String) {
					var value:Float = Std.parseFloat(text);
					if (!Math.isNaN(value))
						applyBpm(value);
				});
			}
		} else if (panelMode == 'event' && panelEvent != null && panelRow >= 2) {
			var field = eventFields()[panelRow - 2];
			if (field.kind == 'bool')
				return;

			var shown:Dynamic = argValue(panelEvent.data, field.key);
			prompt.open(field.key, shown == null ? '' : Std.string(shown), function(text:String) {
				setEventField(field, text);
			});
		}
	}

	function setEventField(field:game.controllers.events.EventManager.EventField, text:String):Void {
		if (panelEvent == null)
			return;

		var value:Dynamic = text;
		if (field.kind == 'float') {
			var number:Float = Std.parseFloat(text);
			if (Math.isNaN(number))
				return;
			if (field.min != null)
				number = Math.max(field.min, number);
			if (field.max != null)
				number = Math.min(field.max, number);
			value = number;
		}

		pushUndoOnce();
		ensureArgs(panelEvent.data);
		Reflect.setField(panelEvent.data.arguments, field.key, value);
		refreshEvent(panelEvent);
		markDirty();
	}

	function formatSeconds(ms:Float):String {
		return Std.string(Math.round(ms) / 1000) + 's';
	}

	function refreshPanel():Void {
		if (panel == null)
			return;

		var lines:Array<String> = [];
		var rowIndex:Int = 0;

		function row(label:String, value:String):Void {
			lines.push((panelRow == rowIndex ? '> ' : '   ') + label + ': ' + value);
			rowIndex++;
		}

		if (panelMode == 'setup') {
			lines.push('SETUP');
			lines.push('Up/Down: choose · Left/Right: change (Shift: bigger steps) · Enter: type · Tab: close');
			lines.push('');

			row('Stage', SONG.songData.meta.stage ?? ChartDefaults.FALLBACK_STAGE);
			for (c in SONG.chars)
				row(roleName(c.role) + ' (' + c.id + ')', c.name ?? c.id);
			row('Scroll speed', Std.string(SONG.songData.meta.speed));
			row('BPM', Std.string(SONG.songData.meta.bpm));

			lines.push('');
			lines.push('Changing the BPM keeps every note at its time in the song.');
			lines.push('The grid follows this starting BPM; "Change BPM" events are not drawn on it.');
		} else if (panelMode == 'event' && panelEvent != null) {
			var data = panelEvent.data;
			lines.push('EVENT');
			lines.push('Up/Down: choose · Left/Right: change · Enter: type · Del: remove event · Tab: close');
			lines.push('');

			row('Time', formatSeconds(data.time));
			row('Type', data.name);

			var fields = eventFields();
			for (f in fields) {
				var shown:Dynamic = argValue(data, f.key);
				row(f.key, shown == null ? '' : Std.string(shown));
			}

			if (game.controllers.events.EventManager.findSchema(data.name) == null) {
				lines.push('');
				lines.push('A custom event: edit its arguments in the chart file.');
				lines.push(haxe.Json.stringify(data.arguments));
			}
		}

		if (prompt.active) {
			lines.push('');
			lines.push(prompt.label + ': ' + prompt.text + '_    (Enter: accept · Esc: cancel)');
		}

		panel.show(lines);
	}
}
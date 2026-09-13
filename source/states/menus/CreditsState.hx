package states.menus;

import flixel.util.FlxColor;
import core.rhythm.audio.MasterAudio;
import modding.scripting.types.ScriptClass;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CreditsState extends MusicBeatState {
	#if windows
	static final CREDITS_FONT = 'Consolas';
	#elseif mac
	static final CREDITS_FONT = 'Menlo';
	#else
	static final CREDITS_FONT = 'Courier New';
	#end
	static final SCROLL_SPEED:Float = 60;

	static final HEADER_SIZE:Int = 22;
	static final BODY_SIZE:Int = 16;

	static final HEADER_COLOR:FlxColor = FlxColor.YELLOW;
	static final BODY_COLOR:FlxColor = FlxColor.WHITE;

	static final PADDING_X:Float = 0.06;
	static final GAP_AFTER_HEADER:Float = 6;
	static final GAP_AFTER_SECTION:Float = 36;

	var acceptOption:Bool = false;
	var totalHeight:Float = 0;

	var bg:flixel.FlxSprite;

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		MasterAudio.playMenu(Paths.getPath('menus/freeplayRandom/freeplayRandom', 'music'), 0.6, 145);

		bg = new flixel.FlxSprite().makeGraphic(FlxG.width, 10, FlxColor.BLACK);
		bg.scrollFactor.set(1, 1);
		add(bg);

		buildCredits();

		bg.scale.y = (totalHeight + FlxG.height * 2) / 10;
		bg.updateHitbox();
		bg.y = -FlxG.height;

		camera.scroll.y = 0;
	}

	function buildCredits() {
		var creditsData = FormatJson.readJson(Paths.getPath('data/credits', 'json'));
        if (creditsData == null)
            creditsData = getCreditsData();

		var curY:Float = FlxG.height * 0.35 + GAP_AFTER_SECTION * 2;

		for (entry in creditsData) {
			var header = makeText(FlxG.width * PADDING_X, curY, entry.header, HEADER_SIZE, HEADER_COLOR);
			add(header);
			curY += header.height + GAP_AFTER_HEADER;

			for (item in entry.body) {
				var line = makeText(FlxG.width * PADDING_X + 16, curY, item.line, BODY_SIZE, BODY_COLOR);
				add(line);
				curY += line.height + 4;
			}

			curY += GAP_AFTER_SECTION;
		}

		var endText = makeText(FlxG.width * PADDING_X, curY + GAP_AFTER_SECTION, 'Thanks for playing!', HEADER_SIZE, HEADER_COLOR, CENTER);
		endText.x = (FlxG.width - endText.fieldWidth) * 0.5;
		add(endText);

		curY += endText.height + GAP_AFTER_SECTION * 2;

		totalHeight = curY;
	}

	function makeText(x:Float, y:Float, text:String, size:Int, color:FlxColor, ?align:FlxTextAlign):FlxText {
		var t = new FlxText(x, y, 0, text);
		t.font = CREDITS_FONT;
		t.setFormat(CREDITS_FONT, size, color, align ?? FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, true);
		t.fieldWidth = FlxG.width * (1 - PADDING_X * 2);
		t.antialiasing = SaveData.data.antialiasing;
		t.scrollFactor.set(1, 1);
		return t;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (acceptOption)
			return;

		if (Controls.BACK) {
			exitCredits();
			return;
		}

		camera.scroll.y += SCROLL_SPEED * elapsed;

		if (camera.scroll.y >= totalHeight) {
			exitCredits();
		}
	}

	function exitCredits() {
		if (acceptOption)
			return;
		acceptOption = true;

		camera.fade(FlxColor.BLACK, 0.8, false, function() {
			ScriptClass.switchState('MainMenuState');
		});
	}

	function getCreditsData():Array<{header:String, body:Array<{line:String}>}> {
		return [
			{header: 'Friday Night Funkin\'', body: [{line: 'A video game created by'}, {line: 'The Funkin\' Crew Inc.'}]},
			{
				header: 'The Funkin\' Crew Inc. Shareholders',
				body: [
					{line: 'ninjamuffin99'},
					{line: 'PhantomArcade'},
					{line: 'Kawai Sprite'},
					{line: 'evilsk8r'}
				]
			},
			{header: 'Direction and Art Lead', body: [{line: 'PhantomArcade'}]},
			{header: 'Music Lead', body: [{line: 'Isaac "Kawai Sprite" Garcia'}]},
			{header: 'Co-Direction and Programming Lead', body: [{line: 'ninjamuffin99'}]},
			{header: 'Mobile Lead', body: [{line: 'MoonDroid (Zack)'}]},
			{header: 'Production Manager', body: [{line: 'Hundrec'}]},
			{header: 'Team Organizers', body: [{line: 'Hundrec'}, {line: 'AbnormalPoof'}]},
			{header: 'Producer', body: [{line: 'Kawa Teaño'}]},
			{header: 'Artists', body: [{line: 'PhantomArcade'}, {line: 'evilsk8r'}, {line: 'beck'}]},
			{header: 'Pixel Art', body: [{line: 'moawling'}, {line: 'IGJHSpritin'}]},
			{header: 'Cutscene Storyboards & SFX', body: [{line: 'PhantomArcade'}]},
			{header: 'Additional Background Design', body: [{line: 'Red Minus'}]},
			{
				header: 'Cutscene Animation',
				body: [
					{line: 'Figburn'},
					{line: 'Sade'},
					{line: 'Topium'},
					{line: 'BlairTheUnseriousGuy'}
				]
			},
			{header: 'Cutscene Cleanup', body: [{line: 'PennilessRagamuffin'}, {line: 'beck'}]},
			{header: 'Cutscene Background Art', body: [{line: 'beck'}]},
			{
				header: 'Additional Art',
				body: [
					{line: 'Jeff Bandelin'},
					{line: 'Mogy64'},
					{line: 'ChipsGoWoah'},
					{line: 'Min Ho Kim (Deegeemin)'},
					{line: 'PKettles'},
					{line: 'peepo173'}
				]
			},
			{
				header: 'Additional Character Design',
				body: [
					{line: 'Tom Fulp - Pico School Characters'},
					{line: 'JohnnyUtah - Tankman'},
					{line: 'SrPelo - Skid and Pump'},
					{line: 'Magna - Otis'},
					{line: 'gacktenzo - Preppy Otis'}
				]
			},
			{header: 'Music Production', body: [{line: 'Saruky'}, {line: 'crisp'}]},
			{
				header: 'Featured Guest Musicians (thus far)',
				body: [
					{line: 'Bassetfilms'},
					{line: 'Kohta Takahashi'},
					{line: 'Lotus Juice'},
					{line: 'METAROOM'},
					{line: 'nuphory'},
					{line: 'Saster'},
					{line: 'six impala'},
					{line: 'TeraVex'},
					{line: 'That Andy Guy'},
					{line: 'tsuyunoshi'},
					{line: 'Xploshi'},
					{line: 'Tee Lopes'},
					{line: 'RRThiel'}
				]
			},
			{header: 'Programming', body: [{line: 'Eric "EliteMasterEric" Myllyoja'}, {line: 'fabs'}, {line: 'KadeDev'}]},
			{
				header: 'Additional Programming',
				body: [
					{line: 'Jenny Crowe'},
					{line: 'ember ana'},
					{line: 'Mike Welsh'},
					{line: 'Saharan'},
					{line: 'Ian Harrigan'},
					{line: 'Osaka Red LLC: Thomas J Webb'},
					{line: 'Emma (MtH)'},
					{line: 'George Kurelic'},
					{line: 'Will Blanton'},
					{line: 'Victor - Cheemsandfriends'},
					{line: 'Hundrec'},
					{line: 'AbnormalPoof'},
					{line: 'MaybeMaru'}
				]
			},
			{
				header: 'Mobile Porting',
				body: [
					{line: 'MAJigsaw77'},
					{line: 'Luckydog7'},
					{line: 'Karim Akra'},
					{line: 'sector_5'}
				]
			},
			{header: 'Devops and Additional Internal Tooling', body: [{line: 'ember ana'}]},
			{
				header: 'Gameplay Design',
				body: [
					{line: 'PhantomArcade'},
					{line: 'Cameron Taylor'},
					{line: 'Jenny Crowe'},
					{line: 'Spazkid'},
					{line: 'fabs'},
					{line: 'Emma (MtH)'}
				]
			},
			{header: 'Kickstarter Backer Portal Programming', body: [{line: 'Shingai Shamu'}]},
			{
				header: 'Merchandise Partners and Designers',
				body: [
					{line: 'Needlejuice Records: Jace McLain'},
					{line: 'Needlejuice Records: Brandon Brown'},
					{line: 'Type-4: Coby Win'},
					{line: 'IvanAlmighty'},
					{line: 'Mogy64'},
					{line: 'ChipsGoWoah'},
					{line: 'Min Ho Kim'},
					{line: 'PKettles'},
					{line: 'Jeff Bandelin'},
					{line: 'PhantomArcade'},
					{line: 'evilsk8r'},
					{line: 'beck'},
					{line: 'Makeship: Seebs'},
					{line: 'Makeship: Anna N'}
				]
			},
			{header: 'Production and Business Development Partner - Windflower Games', body: [{line: 'Sunni Pavlovic'}, {line: 'Kristen Lynch'}]},
			{header: 'Additional Administrative Assistance', body: [{line: 'moawling'}]},
			{
				header: 'Quality Assurance - Indium Play',
				body: [
					{line: 'Lead Tester: Mihajlo Vuković'},
					{line: 'Tester: Andrej Naumovski'},
					{line: 'Dajana Dimovska'}
				]
			},
			{
				header: 'Accounting: Molinari Oswald',
				body: [
					{line: 'Francis Molinari'},
					{line: 'Aaron Hofmann'},
					{line: 'Katherine Stauffer'},
					{line: 'Jane Haring'}
				]
			},
			{
				header: 'US Legal: Odin Law',
				body: [
					{line: 'Brandon Huffman'},
					{line: 'Michele Robichaux'},
					{line: 'Connor Richards'},
					{line: 'Pam Driver'},
					{line: 'Jacob Barefoot'}
				]
			},
			{header: 'CA Legal: DLA Piper', body: [{line: 'Ryan Black'}, {line: 'Brian Wong'}]},
			{
				header: 'Special Thanks',
				body: [
					{line: 'Tom Fulp'},
					{line: 'Jeff Bandelin'},
					{line: 'The entire Molinari Oswald Crew'},
					{line: 'The entire Odin Law function'},
					{line: 'SrPelo'}
				]
			},
			{
				header: 'Cameron would like to specially thank',
				body: [
					{line: 'henry, snackers, digi, joemega, caddy, pewpew'},
					{line: 'milkhead jack'},
					{line: 'katt'},
					{line: 'arko, pepe, cashu, ookiyo'},
					{line: 'Krystin, Kaye-lyn, and Cassidy, Mack, Levi, and Jasmine.'},
					{line: 'Laurel'},
					{line: 'Clone Hero'},
					{line: 'Innersloth, Puffballs, Forest and Victoria'},
					{line: 'StuffedWombat'},
					{line: 'mmatt_ugh'},
					{line: 'lucas and jack taterguy and marty emrox'},
					{line: 'Luis'},
					{line: 'GeoKureli, Will Blanton, Austin East, Squidly'},
					{line: 'fizzd'},
					{line: 'bbpanzu'},
					{line: 'Etika'},
					{line: 'Foamymuffin (insert travis scott lyrics here)'},
					{line: 'SiIvaGunner'},
					{line: 'Freddie Dredd'}
				]
			},
			{header: 'Kawa would like to specially thank', body: [{line: 'Alexei Pepers'}, {line: 'Xalavier Nelson Jr.'}]},
			{header: 'Eric would like to specially thank', body: [{line: 'Rob and Jill Myllyoja'}, {line: 'KadeDev'}, {line: 'Shadow Mario'}]},
			{header: 'Hazel (Ravy) would like to specially thank', body: [{line: 'd1ggo'}]},
			{
				header: 'Mobile Team special thanks',
				body: [
					{line: 'cub, setai'},
					{line: 'GalacticBaguette, Yowze, Snovi'},
					{line: 'AguaCrunch, pb_lauro, Rulet, Rusron, Megalo_palewhite, Serizyu'},
					{line: '8-bitryan'},
					{line: 'Stax, NoraYotsu, AndroidSharky, IdioticLuwuke'},
					{line: 'PeppyWall, Klavier, Roadr, Limon'},
					{line: 'Koniro, Key, Zuki, LunaMyria, Rattatuwu, ToffeeCaramel'},
					{line: 'Ninkey, Snak, Codist'},
					{line: 'ValenPratama'},
					{line: 'yetet (June), IDontCareAbtKaz'},
					{line: 'Schepka'},
					{line: 'Amari, DatRand (Vlad), Ressu2, Kekkra, CaptainRoku'},
					{line: 'cat (Ariel), deathgobrr'},
					{line: 'Mario Master (MasterX)'},
					{line: 'richTrash21, PurSnake, Naisonji, HopKa, Matr4ss'},
					{line: 'Redar13, Sirox, Shufa, D.Dregz, Sodaree'},
					{line: 'dUmer, G0lda, Voodoo, Vemer, Sadshrimp'}
				]
			},
		];
	}
}

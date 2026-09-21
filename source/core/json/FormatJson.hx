package core.json;

import sys.FileSystem;
import core.json.JsonWatcher;
import ale.json.Json as AleJson;
import ale.json.Config;

class FormatJson {
	public static var _configured:Bool = false;

	public static function _configure() {
		if (_configured)
			return;
		_configured = true;
		Config.FILE_CHECKER = sys.FileSystem.exists;
		Config.FILE_READER = sys.io.File.getContent;
		Config.PATH = '';
		Config.EXTENSION = '';
	}

	public static function readJson<T>(data:String, ?callback:Void->Void):Null<T> {
		if (data == null || !sys.FileSystem.exists(data))
			return null;

		#if HSCRIPT_ALLOWED
		if (core.ConfigMain.globalData.developerMode)
			JsonWatcher.watch(data, callback);
		#end

		_configure();

		return cast AleJson.parse(data);
	}

	public static function getIconDataPlaceholder(?customData:core.json.objects.CharacterData.IconData):core.json.objects.CharacterData.IconData {
		if (customData == null) {
			return {
				props: null,
				bumpInBeats: true,
				stepTempo: 2.0
			};
		}

		return {
			props: customData.props != null ? customData.props : null,
			bumpInBeats: customData.bumpInBeats != null ? customData.bumpInBeats : true,
			stepTempo: customData.stepTempo != null ? customData.stepTempo : 2.0
		};
	}

	public static function getCharDataPlaceholder(characterData:core.json.objects.CharacterData) {
		characterData = {
			meta: {
				isPlayer: true
			},
			gameplay: {
				position: [13, 4],
				cameraOffset: [-300, -200],
				death: {
					character: "bf-death",
					sound: "default/fnf_loss_sfx",
					music: "default/gameOver",
					endSound: "default/gameOverEnd"
				},
				idleAfterSing: true
			},
			render: {
				layers: [
					{
						name: "Undefined Character",
						path: "bf",
						position: [0, 0],
						scale: [1, 1],
						alpha: 1.0,
						visible: true,
						flipX: false,
						flipY: false,
						antialiasing: true,
						anims: [
							{
								name: "idle",
								prefix: "BF idle dance",
								offsets: [-13, -4],
								framerate: 24,
								looped: false
							},
							{
								name: "singLEFT",
								prefix: "BF NOTE LEFT",
								offsets: [-10, -7],
								framerate: 24,
								looped: false
							},
							{
								name: "singLEFTmiss",
								prefix: "BF NOTE LEFT MISS",
								offsets: [-13, -18],
								framerate: 24,
								looped: false
							},
							{
								name: "singRIGHT",
								prefix: "BF NOTE RIGHT",
								offsets: [32, -11],
								framerate: 24,
								looped: false
							},
							{
								name: "singRIGHTmiss",
								prefix: "BF NOTE RIGHT MISS",
								offsets: [30, -24],
								framerate: 24,
								looped: false
							},
							{
								name: "singUP",
								prefix: "BF NOTE UP",
								offsets: [1, -76],
								framerate: 24,
								looped: false
							},
							{
								name: "singUPmiss",
								prefix: "BF NOTE UP MISS",
								offsets: [10, -70],
								framerate: 24,
								looped: false
							},
							{
								name: "singDOWN",
								prefix: "BF NOTE DOWN",
								offsets: [2, 34],
								framerate: 24,
								looped: false
							},
							{
								name: "singDOWNmiss",
								prefix: "BF NOTE DOWN MISS",
								offsets: [0, 23],
								framerate: 24,
								looped: false
							},
							{
								name: "hey",
								prefix: "BF HEY!!",
								offsets: [-12, -14],
								framerate: 24,
								looped: false
							},
							{
								name: "cheer",
								prefix: "Boyfriend YEAH cheer",
								offsets: [30, -20],
								framerate: 24,
								looped: false
							},
							{
								name: "scared",
								prefix: "BF idle shaking",
								offsets: [0, 0],
								framerate: 24,
								looped: false
							}
						]
					}
				]
			},
			icon: {
				props: {
					name: "bf-icon",
					path: "bf",
					flipX: false,
					frameScale: [150, 150],
					firstAnim: "normal",
					anims: [
						{
							name: "losing",
							indices: [1],
							offsets: [0, 0],
							framerate: 24,
							looped: false
						},
						{
							name: "normal",
							indices: [0],
							offsets: [0, 0],
							framerate: 24,
							looped: false
						}
					]
				},
				bumpInBeats: true,
				stepTempo: 2
			}
		}
	}
}

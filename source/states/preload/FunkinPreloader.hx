package states;

import flixel.system.FlxBasePreloader;

class FunkinPreloader extends FlxBasePreloader {}

enum abstract FunkinPreloaderState(String) to String {
	/**
	 * The state before downloading has begun.
	 * Moves to either `DownloadingAssets` or `CachingGraphics` based on platform.
	 */
	public var NotStarted;

	/**
	 * Downloading assets.
	 * On HTML5, Lime will do this for us, before calling `onLoaded`.
	 * On Native, this step will be completed immediately, and we'll go straight to `CachingGraphics`.
	 */
	public var DownloadingAssets;

	/**
	 * Preloading play assets.
	 * Loads the `manifest.json` for the `gameplay` library.
	 * If we make the base preloader do this, it will download all the assets as well,
	 * so we have to do it ourselves.
	 */
	public var PreloadingPlayAssets;

	/**
	 * Loading FireTongue, loading Polymod, parsing and instantiating module scripts.
	 */
	public var InitializingScripts;

	/**
	 * Loading all graphics from the `core` library to the cache.
	 */
	public var CachingGraphics;

	/**
	 * Loading all audio from the `core` library to the cache.
	 */
	public var CachingAudio;

	/**
	 * Loading all data files from the `core` library to the cache.
	 */
	public var CachingData;

	/**
	 * Parsing all XML files from the `core` library into FlxFramesCollections and caching them.
	 */
	public var ParsingSpritesheets;

	/**
	 * Parsing stage data and scripts.
	 */
	public var ParsingStages;

	/**
	 * Parsing character data and scripts.
	 */
	public var ParsingCharacters;

	/**
	 * Parsing song data and scripts.
	 */
	public var ParsingSongs;

	/**
	 * Finishing up.
	 */
	public var Complete;

	/**
	 * Formats the status text for progress bar display.
	 * @param steps The total number of steps. Defaults to `FunkinPreloader.TOTAL_STEPS`.
	 * @param suffix What to append to the end of the text, usually those dynamic ellipsis. Defaults to an empty string.
	 * @return String 'Loading \n0/$steps $suffix' for example
	 */
	public function getProgressLeftText(?steps:Int, ?suffix:String):String {
		steps = steps ?? FunkinPreloader.TOTAL_STEPS;
		suffix = suffix ?? '';
		switch (this) {
			case NotStarted:
				return 'Loading \n0/$steps $suffix';
			case DownloadingAssets:
				return 'Downloading assets \n1/$steps $suffix';
			case PreloadingPlayAssets:
				return 'Preloading assets \n2/$steps $suffix';
			case InitializingScripts:
				return 'Initializing scripts \n3/$steps $suffix';
			case CachingGraphics:
				return 'Caching graphics \n4/$steps $suffix';
			case CachingAudio:
				return 'Caching audio \n5/$steps $suffix';
			case CachingData:
				return 'Caching data \n6/$steps $suffix';
			case ParsingSpritesheets:
				return 'Parsing spritesheets \n7/$steps $suffix';
			case ParsingStages:
				return 'Parsing stages \n8/$steps $suffix';
			case ParsingCharacters:
				return 'Parsing characters \n9/$steps $suffix';
			case ParsingSongs:
				return 'Parsing songs \n10/$steps $suffix';
			case Complete:
				return 'Finishing up \n$steps/$steps $suffix';
			default:
				return null;
		}
	}
}

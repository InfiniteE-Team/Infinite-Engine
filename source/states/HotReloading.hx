package states;

/**
 * Optional interface for states that support multi-step pre-construction
 * (such as PlayState).
 * The state is launched as soon as the assets have finished loading.
 */
interface HotReloading {
	public var prebuilt(default, null):Bool;

	public function prebuildStep():Bool;
}

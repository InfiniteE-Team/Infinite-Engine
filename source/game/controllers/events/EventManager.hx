package game.controllers.events;

import game.PlayState;
import core.json.song.SongData.EventsData;
import game.objects.sprites.Character;

class EventManager {
	public var pendingEvents:Array<EventsData> = [];
	public var onEvent:(EventsData) -> Void = null;

	public function new() {}

	public function loadEvents(events:Array<EventsData>) {
		pendingEvents = events.copy();
		pendingEvents.sort((a, b) -> Std.int(a.time - b.time));

		onEvent = handleEvent;
	}

	function handleEvent(event:EventsData) {
		switch (event.name) {
			case 'Camera Follow':
				var charId:String = Reflect.field(event.arguments, 'char');
				var char = PlayState.instance.chars.get(charId);
				if (char == null) {
					trace('Camera Follow char "$charId" not found');
					return;
				}
				PlayState.instance.cameraController.followChar = cast(char, Character);
		}
	}

	public function updateEvents(songTime:Float) {
		while (pendingEvents.length > 0 && pendingEvents[0].time <= songTime) {
			var event = pendingEvents.shift();
			if (onEvent != null)
				onEvent(event);
		}
	}

	public function destroy() {
		pendingEvents = null;
		onEvent = null;
	}
}

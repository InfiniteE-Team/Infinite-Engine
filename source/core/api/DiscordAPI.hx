package core.api;

#if DISCORD_ALLOWED
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types.DiscordButton;
import hxdiscord_rpc.Types.DiscordEventHandlers;
import hxdiscord_rpc.Types.DiscordRichPresence;
import hxdiscord_rpc.Types.DiscordUser;
import sys.thread.Thread;
#end

class DiscordAPI {
	static final DISCORD_CLIENT_ID:Null<String> = "1534274562496270356"; // Replace with your actual Discord client ID

	public static var instance(get, never):DiscordAPI;
	static var _instance:Null<DiscordAPI> = null;

	public static function initWithId(clientId:String):Void {
		#if DISCORD_ALLOWED
		trace(' DISCORD Initializing connection...');

		if (clientId == null || clientId == "" || clientId.contains(" ")) {
			FlxG.log.warn("Tried to initialize Discord connection, but credentials are invalid!");
			return;
		}

		@:nullSafety(Off)
		{
			Discord.Initialize(clientId, cpp.RawPointer.addressOf(instance.handlers), false, "");
		}

		instance.createDaemon();
		#end
	}

	static function get_instance():DiscordAPI {
		if (DiscordAPI._instance == null)
			_instance = new DiscordAPI();
		if (DiscordAPI._instance == null)
			throw "Could not initialize singleton DiscordAPI!";
		return DiscordAPI._instance;
	}

	#if DISCORD_ALLOWED
	var handlers:DiscordEventHandlers;
	#end

	private function new() {
		#if DISCORD_ALLOWED
		trace(' DISCORD Initializing event handlers...');

		handlers = new DiscordEventHandlers();

		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		#end
	}

	/**
	 * @returns `false` if the client ID is invalid.
	 */
	static function hasValidCredentials():Bool {
		return !(DISCORD_CLIENT_ID == null || DISCORD_CLIENT_ID == "" || (DISCORD_CLIENT_ID != null && DISCORD_CLIENT_ID.contains(" ")));
	}

	var daemon:Null<Thread> = null;

	function createDaemon():Void {
		#if DISCORD_ALLOWED
		daemon = Thread.create(doDaemonWork);
		#end
	}

	function doDaemonWork():Void {
		#if DISCORD_ALLOWED
		while (true) {
			Discord.RunCallbacks();
			Sys.sleep(2);
		}
		#end
	}

	public function shutdown():Void {
		#if DISCORD_ALLOWED
		trace(' DISCORD Shutting down...');
		Discord.Shutdown();
		#end
	}

	public function setPresence(params:DiscordAPIPresenceParams):Void {
		#if DISCORD_ALLOWED
		var presence:DiscordRichPresence = new DiscordRichPresence();

		// Presence should always be playing the game.
		presence.type = DiscordActivityType_Playing;

		presence.largeImageText = "Friday Night Funkin'";

		presence.state = cast(params.state, Null<String>) ?? "";
		presence.details = cast(params.details, Null<String>) ?? "";

		presence.largeImageKey = cast(params.largeImageKey, Null<String>) ?? "icon";

		presence.smallImageKey = cast(params.smallImageKey, Null<String>) ?? "";

		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
		#end
	}

	#if DISCORD_ALLOWED
	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		trace(' DISCORD Client has connected!');

		final username:String = request[0].username;
		final globalName:String = request[0].globalName;
		final discriminator:Null<Int> = Std.parseInt(request[0].discriminator);

		if (discriminator != null && discriminator != 0) {
			trace(' DISCORD User: ${username}#${discriminator} (${globalName})');
		} else {
			trace(' DISCORD User: @${username} (${globalName})');
		}
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		trace(' DISCORD Client has disconnected! ($errorCode) "${Std.string(message)}"');
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		trace(' DISCORD Client has received an error! ($errorCode) "${Std.string(message)}"');
	}
	#end
}

typedef DiscordAPIPresenceParams = {
	var state:String;
	var details:Null<String>;
	var ?largeImageKey:String;
	var ?smallImageKey:String;
}

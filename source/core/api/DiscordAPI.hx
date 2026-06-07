package core.api;

import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import sys.thread.Thread;

class DiscordAPI
{
    private static var isInitialized:Bool = false;

    public static function init():Void
	{
        if (isInitialized) return;

		Sys.println('Initializing Discord RPC...');

		final handlers:DiscordEventHandlers = new DiscordEventHandlers();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize("345229890980937739", cpp.RawPointer.addressOf(handlers), false, null);

        isInitialized = true;

		Thread.create(function():Void
		{
			while (true)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end

				Discord.RunCallbacks();

				Sys.sleep(0.1);
			}
		});
	}

    public static function changePresence(details:String, state:String, ?smallImageKey:String = ""):Void
    {
        final discordPresence:DiscordRichPresence = new DiscordRichPresence();
        discordPresence.type = DiscordActivityType_Playing; // "Playing" tiene más sentido para un juego
        discordPresence.state = state;
        discordPresence.details = details;
        discordPresence.largeImageKey = "canary-large";
        
        if (smallImageKey != "") discordPresence.smallImageKey = smallImageKey;

        Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
    }

    public static function shutdown():Void
    {
        if (!isInitialized) return;
        
        Trace.traceOnce('Shutting down Discord RPC...');
        isInitialized = false;
        Discord.Shutdown();
    }

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		final username:String = request[0].username;
		final globalName:String = request[0].username;
		final discriminator:Int = Std.parseInt(request[0].discriminator);

		if (discriminator != 0)
			Trace.traceOnce('Discord: Connected to user ${username}#${discriminator} ($globalName)');
		else
			Trace.traceOnce('Discord: Connected to user @${username} ($globalName)');

		final discordPresence:DiscordRichPresence = new DiscordRichPresence();
		discordPresence.type = DiscordActivityType_Watching;
		discordPresence.state = "West of House";
		discordPresence.details = "Frustration";
		discordPresence.largeImageKey = "canary-large";
		discordPresence.smallImageKey = "ptb-small";

		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));

        changePresence("In the Menus", "Starting Engine...");
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Trace.traceOnce('Discord: Disconnected ($errorCode:$message)', true);
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Trace.traceOnce('Discord: Error ($errorCode:$message)', true);
	}
}
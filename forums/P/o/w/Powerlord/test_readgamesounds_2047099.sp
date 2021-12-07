#include <sourcemod>
#include <readgamesounds>

public Plugin:myinfo =
{
	name = "Test ReadGameSounds",
	description = "Test ReadGameSounds and display the returned values",
	author = "Powerlord",
	version = "1.0.0",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("readsound", Cmd_ReadSound, ADMFLAG_GENERIC, "Read a sound and display its info");
	RegAdminCmd("gamesound", Cmd_GameSound, ADMFLAG_GENERIC, "Play a game sound");
	RegAdminCmd("gamesoundall", Cmd_GameSoundAll, ADMFLAG_GENERIC, "Play a game sound to everyone");
}

public Action:Cmd_ReadSound(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Must specify a sound name");
		return Plugin_Handled;
	}
	new String:gameSound[PLATFORM_MAX_PATH];
	GetCmdArg(1, gameSound, sizeof(gameSound));
	
	new channel;
	new soundLevel;
	new Float:volume;
	new pitch;
	new String:sample[PLATFORM_MAX_PATH];
	
	if (GetGameSoundParams(gameSound, channel, soundLevel, volume, pitch, sample, PLATFORM_MAX_PATH))
	{
		ReplyToCommand(client, "Sound %s: channel: %d, soundLevel: %d, volume: %f, pitch: %d, sample: %s", gameSound, channel, soundLevel, volume, pitch, sample);
	}
	else
	{
		ReplyToCommand(client, "Could not find sound: %s", gameSound);
	}
	return Plugin_Handled;
}

public Action:Cmd_GameSound(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		ReplyToCommand(client, "Must specify a sound name");
		return Plugin_Handled;
	}
	
	new String:gameSound[PLATFORM_MAX_PATH];
	GetCmdArg(1, gameSound, sizeof(gameSound));
	TrimString(gameSound);
	StripQuotes(gameSound);
	TrimString(gameSound);
	
	EmitGameSoundToClient(client, gameSound);
	return Plugin_Handled;
}

public Action:Cmd_GameSoundAll(client, args)
{
	if (args == 0)
	{
		ReplyToCommand(client, "Must specify a sound name");
		return Plugin_Handled;
	}
	
	new String:gameSound[PLATFORM_MAX_PATH];
	GetCmdArg(1, gameSound, sizeof(gameSound));
	
	TrimString(gameSound);
	StripQuotes(gameSound);
	TrimString(gameSound);
	
	EmitGameSoundToAll(gameSound);
	return Plugin_Handled;
}

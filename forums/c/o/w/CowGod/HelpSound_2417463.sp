#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "cow"
#define PLUGIN_VERSION "1337.69"

#include <sourcemod>
#include <sdktools>
#include <EmitSoundAny>

public Plugin myinfo = 
{
	name = "HelpSound",
	author = PLUGIN_AUTHOR,
	description = "Plays Sound To Player on command",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	PrecacheSoundAny("help/help.mp3");
	RegConsoleCmd("help", DoSound, "Play Sound!");
}

public OnConfigsExecuted()
{
	PrecacheSoundAny("help/help.mp3");
    AddFileToDownloadsTable("sound/help/help.mp3");
    PrecacheSoundAny("help/help.mp3", true);
}


public Action DoSound(client, args)
{
	EmitSoundToClientAny("help/help.mp3");
}
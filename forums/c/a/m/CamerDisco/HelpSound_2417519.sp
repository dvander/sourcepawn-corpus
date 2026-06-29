#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "cow"
#define PLUGIN_VERSION "1337.69"
#define MAX_FILE_LEN 80 

#include <sourcemod>
#include <sdktools>
#include <EmitSoundAny>

new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN]; 

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
	g_CvarSoundName = CreateConVar("sm_help_sound", "help/help.mp3", "Help sound");
}

public OnConfigsExecuted()
{
    GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
    decl String:buffer[MAX_FILE_LEN];
    PrecacheSoundAny(g_soundName, true);
    Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
    AddFileToDownloadsTable(buffer);
} 


public Action DoSound(client, args)
{
    EmitSoundToClientAny(client, g_soundName); 
}
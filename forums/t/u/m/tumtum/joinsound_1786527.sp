#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#pragma semicolon 1
#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

#define PLUGIN_VERSION "1.0"
public Plugin:myinfo = 
{
	name = "CS:GO Sound",
	author = "Team-Secretforce.com",
	description = "Join Sound on your CS:GO Server",
	version = PLUGIN_VERSION,
	url = "http://www.Team-Secretforce.com/"
};
public OnPluginStart()
{
	// Create the rest of the cvar's
CreateConVar("sm_welcome_snd_version", PLUGIN_VERSION, "CS:GO Sound Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
g_CvarSoundName = CreateConVar("sm_start_sound", "music/welcome/secretforce.mp3", "Welcome sound");
}
public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}
public OnClientPostAdminCheck(client)
{
EmitSoundToClient(client,g_soundName);
}
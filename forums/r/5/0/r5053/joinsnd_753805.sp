#include <sourcemod>
#include <sdktools>


#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

#define PLUGIN_VERSION "1.0.0"
public Plugin:myinfo = 
{
	name = "Welcome Sound",
	author = "R-Hehl",
	description = "Plays Welcome Sound to connecting Players",
	version = PLUGIN_VERSION,
	url = "http://www.compactaim.de/"
};
public OnPluginStart()
{
	// Create the rest of the cvar's
CreateConVar("sm_welcome_snd_version", PLUGIN_VERSION, "Welcome Sound Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
g_CvarSoundName = CreateConVar("sm_join_sound", "consnd/joinserver.mp3", "The sound to play");
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
/* EmitSoundToClient(client,g_soundName); */
ClientCommand(client,"play %s",g_soundName)
}
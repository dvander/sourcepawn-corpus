#include <sourcemod>
#include <sdktools>

#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

public Plugin:myinfo = 
{
	name = "Death Sound",
	author = "Marcus", // Thanks to R-Hehl for some source code.
	description = "Plays a sound when a player dies.",
	version = "0.0.2",
	url = "http://www.sourcemod.net"
};
public OnPluginStart()
{
	g_CvarSoundName = CreateConVar("sm_death_sound", "death_sound/killnotifysound.mp3", "The sound emitted when a player dies.");
	AutoExecConfig();
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
}
public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Thanks Mitch
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client) && !IsFakeClient(attacker))
	{
		//EmitSoundToClient(attacker, g_soundName);
		PlaySound(attacker, g_soundName);
	}
}

PlaySound(client, String:soundpath[])
{
	if(IsClientInGame(client))
		ClientCommand(client, "playgamesound \"%s\"", soundpath);
}
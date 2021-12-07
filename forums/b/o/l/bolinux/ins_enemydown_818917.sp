#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define PLUGIN_VERSION "1.0"
#define MAX_FILE_LEN 80
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

new Handle:cvarMode;

public Plugin:myinfo = {
	name = "Enemy down",
	author = "R3M",
	description = "Enemy down death scream",
	version = PLUGIN_VERSION,
	url = "http://www.econsole.de"
};

public OnPluginStart()
{
	CreateConVar("ins_enemydown_version", PLUGIN_VERSION, "Enemy down Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarMode = CreateConVar("ins_enemydown", "1", "1/0 = Plugin on/off", FCVAR_PLUGIN, true, 1.0); 
	g_CvarSoundName = CreateConVar("ins_enemydown_sound", "player/pain/minorpain7.wav", "Death scream sound");
	HookEvent("player_death", event_PlayerDeath);
}

public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (victim == attacker)
		return Plugin_Continue;

	switch(GetConVarInt(cvarMode))
	{
		case 1:
			EmitSoundToClient(attacker,g_soundName);
	}
	return Plugin_Continue;
}
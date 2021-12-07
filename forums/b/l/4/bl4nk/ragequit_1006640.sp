#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

new Float:g_fLastDeathTime[MAXPLAYERS+1] = {0.0};

new Handle:g_hCvarTime = INVALID_HANDLE;
new Handle:g_hCvarSound = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "RageQuit",
	author = "bl4nk",
	description = "Plays a sound when a client disconnects within a certain time of dieing",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("ragequit.phrases");

	CreateConVar("sm_ragequit_version", PLUGIN_VERSION, "RageQuit Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarTime = CreateConVar("sm_ragequit_max_delay", "10.0", "Time in seconds a player has to leave in to be considered a ragequitter", FCVAR_PLUGIN, true, 0.0, false, _);
	g_hCvarSound = CreateConVar("sm_ragequit_sound", "ragequit/ragequit.mp3", "Path to the sound file to play (relative to the \"sound\" folder)", FCVAR_PLUGIN);

	HookEvent("player_death", Event_PlayerDeath);
}

public OnConfigsExecuted()
{
	decl String:sSoundPath[128], String:sSoundFullPath[192];
	GetConVarString(g_hCvarSound, sSoundPath, sizeof(sSoundPath));
	Format(sSoundFullPath, sizeof(sSoundFullPath), "sound/%s", sSoundPath);

	PrecacheSound(sSoundPath);
	AddFileToDownloadsTable(sSoundFullPath);
}

public bool:OnClientConnect(client)
{
	g_fLastDeathTime[client] = 0.0;
	return true;
}

public OnClientDisconnect(client)
{
	if (g_fLastDeathTime[client] > 0.0 && (GetEngineTime() - g_fLastDeathTime[client]) > GetConVarFloat(g_hCvarTime))
	{
		decl String:sSoundPath[128];
		GetConVarString(g_hCvarSound, sSoundPath, sizeof(sSoundPath));

		EmitSoundToAll(sSoundPath);

		PrintToChatAll("%t", "Rage Quitter", client);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	g_fLastDeathTime[iClient] = GetEngineTime();
}
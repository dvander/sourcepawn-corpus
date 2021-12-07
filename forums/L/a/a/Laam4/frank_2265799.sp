#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.3"

ConVar g_hCvarVersion;

public Plugin myinfo = {
	name = "[CS:GO] Show legit profile rank on scoreboard",
	author = "Laam4",
	description = "Show legit profile rank on scoreboard",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2265799"
};

public void OnPluginStart()
{
	g_hCvarVersion = CreateConVar("sm_frank_version", PLUGIN_VERSION, "Fake rank version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarVersion.SetString(PLUGIN_VERSION);

	HookEvent("announce_phase_end", Event_AnnouncePhaseEnd);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_SCORE && !(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_SCORE)) {
		Handle hBuffer = StartMessageOne("ServerRankRevealAll", client);
		if (hBuffer != INVALID_HANDLE)
		{
			EndMessage();
		}
	}
	return Plugin_Continue;
}

public Action Event_AnnouncePhaseEnd(Handle event, const char[] name, bool dontBroadcast)
{
	Handle hBuffer = StartMessageAll("ServerRankRevealAll");
	if (hBuffer != INVALID_HANDLE)
	{
		EndMessage();
	}
	return Plugin_Continue;
}
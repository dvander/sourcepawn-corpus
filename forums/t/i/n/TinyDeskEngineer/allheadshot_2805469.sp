#include <sourcemod>
#include <sdkhooks>
#include <tf2>

public Plugin myinfo =
{
	name = "[TF2] All Headshot",
	description = "Makes all bullet weapons able to headshot",
	author = "Tiny Desk Engineer",
	version = "1.1",
	url = ""
}

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (hitgroup == 1)
	{
		// TF2: the value of DMG_AIRBOAT was reused for DMG_USE_HITLOCATIONS, tf2.inc does not seem to define it though.
		damagetype |= (DMG_AIRBOAT | DMG_CRIT);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
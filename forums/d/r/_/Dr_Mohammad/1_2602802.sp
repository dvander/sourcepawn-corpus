#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define HP_VERSION "1.1"

public Plugin myinfo =
{
	 name = "1 Kill/+5 HP for Admins",
	 author = "Psyk0tik (Crasher_3637), MonsteQ, sidezz, Dr.Mohammad",
	 description = "Gives +5 HP per kill for admins.",
	 version = HP_VERSION,
	 url = "https://forums.alliedmods.net/showthread.php?t=307697"
};

ConVar g_cvHPEnable;
ConVar g_cvHPAdmin;

public void OnPluginStart()
{
	g_cvHPEnable = CreateConVar("hp_enable", "1", "Enable plugin?\n(0: OFF)\n(1: ON)");
	g_cvHPAdmin = CreateConVar("hp_admin", "0", "Enable plugin only for Admin?\n(0: OFF)\n(1: ON)");
	CreateConVar("hp_version", HP_VERSION, "Plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_death", ePlayerDeath);
	HookEvent("player_spawn", Event_Spawn);
	AutoExecConfig(true, "hp_kills_for_admins");
}

public Action ePlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvHPEnable.BoolValue)
	{
		return Plugin_Handled;
	}
	
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	
	if ((!g_cvHPAdmin.BoolValue || (g_cvHPAdmin.BoolValue && IsAdminAllowed(iAttacker))) && IsValidClient(iAttacker) && iAttacker != iVictim)
	{
		SetEntityHealth(iAttacker, GetClientHealth(iAttacker) + 5);
	}
	return Plugin_Continue;
}

public Action Event_Spawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvHPEnable.BoolValue)
	{
		return Plugin_Handled;
	}
	
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (!g_cvHPAdmin.BoolValue || (g_cvHPAdmin.BoolValue && IsAdminAllowed(iClient)))
	{
		SetEntProp(iClient, Prop_Send, "m_ArmorValue", 100);
		SetEntProp(iClient, Prop_Send, "m_bHasHelmet", 1);
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client) && IsPlayerAlive(client));
}

stock bool IsAdminAllowed(int client)
{
	return (CheckCommandAccess(client, "hp_override", ADMFLAG_CUSTOM6, false));
}
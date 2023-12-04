#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define TEAM_INFECTED 3

new tooFarCanTeleport;

bool b_IsCharging[MAXPLAYERS+1];

ConVar z_charge_interval;
float f_ChargerCooldown;

public Plugin myinfo = 
{
	name = "Charger E infinite cooldown fix",
	author = "shrekt",
	description = "Fix the bug while charging and E to teleport to survivors, infinite CD",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	z_charge_interval = FindConVar("z_charge_interval");
	tooFarCanTeleport = FindSendPropInfo("CTerrorPlayer", "m_isCulling");

	HookEvent("charger_charge_start", EventChargeStart);
	HookEvent("charger_charge_end", EventChargerEnd);
}

void EventChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED) return;

	b_IsCharging[client] = true;
}

void EventChargerEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED) return;

	b_IsCharging[client] = false;
}

public Action OnPlayerRunCmd(client, &buttons)
{
	if (buttons & IN_USE && L4D2_GetPlayerZombieClass(client) == 6 && b_IsCharging[client]) 
	{
		if (IsPlayerAbleToTeleport(client))
		{
			f_ChargerCooldown = z_charge_interval.FloatValue;
			L4D2_SetCustomAbilityCooldown(client, f_ChargerCooldown);
			// PrintToChat(client, "Charger CD Fix"); 
		}
		else
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

bool IsPlayerAbleToTeleport(client)
{
	if (GetEntData(client, tooFarCanTeleport, 1)) return true;
	else return false;
}


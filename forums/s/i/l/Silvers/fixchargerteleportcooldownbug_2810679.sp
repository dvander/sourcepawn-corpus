#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define TEAM_INFECTED 3

bool g_bIsCharging[MAXPLAYERS+1];
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

public void OnPluginStart()
{
	z_charge_interval = FindConVar("z_charge_interval");

	HookEvent("charger_charge_start", EventChargeStart);
	HookEvent("charger_charge_end", EventChargerEnd);
	HookEvent("round_end", EventRoundEnd);
}

void EventChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED) return;

	g_bIsCharging[client] = true;
}

void EventChargerEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED) return;

	g_bIsCharging[client] = false;
}

void EventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bIsCharging[i] = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (buttons & IN_USE && GetEntProp(client, Prop_Send, "m_zombieClass") == 6 && g_bIsCharging[client]) 
	{
		if (GetEntProp(client, Prop_Send, "m_isCulling", 1))
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

bool L4D2_SetCustomAbilityCooldown(int client, float time)
{
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability > 0 && IsValidEdict(ability))
	{
		SetEntPropFloat(ability, Prop_Send, "m_duration", time);
		SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + time);
		return true;
	}
	return false;
}
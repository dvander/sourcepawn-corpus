#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CHARGING_SOUND "player/charger/hit/charger_smash_02.wav"
#pragma semicolon 1

bool g_bChargingStart [MAXPLAYERS+1];

public void OnPluginStart()
{
	HookEvent("charger_charge_start", Event_OnChargeStart);
	
	HookEvent("charger_impact", Event_OnChargeEnd);
	HookEvent("charger_charge_end", Event_OnChargeEnd);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bChargingStart[i] = false;
	}
}

public void Event_OnChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 3) return;
	
	g_bChargingStart[client] = true;
	CreateTimer(0.1, Timer_RaiseIncapSurvivor, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public void Event_OnChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 3) return;
	
	g_bChargingStart[client] = false;
}

public Action Timer_RaiseIncapSurvivor(Handle timer, int client)
{
	if (!g_bChargingStart[client]) return Plugin_Stop;
	
	float targetpos[3], chargerpos[3];
	
	for (int target = 1; target <= MaxClients; target++)
	{
		if(IsSurvivorIncapacitated(target))
		{
			GetClientAbsOrigin(target, targetpos);
			GetClientAbsOrigin(client, chargerpos);
			
			if (GetVectorDistance(targetpos, chargerpos) <= 50.0)
			{
				SetEntPropEnt(client, Prop_Send, "m_carryVictim", target);
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

bool IsSurvivorIncapacitated(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 2 
		&& (GetEntProp(client, Prop_Send, "m_isIncapacitated"), 1) 
		&& (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"), 1) 
		&& (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"), 1));
}
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

float g_fClientHurt[MAXPLAYERS+1];
ConVar HealthCost, ShoveSI, ShoveCI;

public Plugin myinfo =
{
	name = "[L4D2] Lose health when shove",
	author = "TBK Duy",
	description = "Unlimited shove but it costs your permanent health.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=335573"
}

public void OnPluginStart()
{ 
	HookEvent("entity_shoved", Event_EntityShoved);
	HookEvent("player_shoved", Event_PlayerShoved);
	HealthCost = CreateConVar("l4d2_shove_lose_health", "1", "How many health costs per shove.", FCVAR_NOTIFY);
	ShoveSI = CreateConVar("l4d2_slh_si", "1", "1 = Shove Special Infected costs your health, 0 = Disable the plugin's effects", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ShoveCI = CreateConVar("l4d2_slh_ci", "1", "1 = Shove Common Infected costs your health, 0 = Disable the plugin's effects", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "l4d2_shove_lose_health");
} 

public Action OnPlayerRunCmd(int client, int &buttons)
{	
	if (GetClientTeam(client) != 2) return Plugin_Continue;
    
	if (buttons & IN_ATTACK2)
	{
		SetEntProp(client, Prop_Send, "m_iShovePenalty", 0, 1);
	}
	
	return Plugin_Continue;
}

public void Event_EntityShoved(Event event, const char[] name, bool dontBroadcast)
{
	if (ShoveCI.IntValue > 0)
	{
		int client = GetClientOfUserId(GetEventInt(event, "attacker"));
		int zombie = event.GetInt("entityid");

		if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsValidCommon(zombie))
		{
			HurtPlayer(client);
		}
	}
}		

public void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	if (ShoveSI.IntValue > 0)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && GetClientTeam(client) == 3)
		{
			HurtPlayer(attacker);
		}
	}
}		

void HurtPlayer(int client)
{
	if( GetGameTime() - g_fClientHurt[client] >= 0.5 )
		g_fClientHurt[client] = GetGameTime();
	else
		return;

	int iHealth = GetClientHealth(client) - GetConVarInt(HealthCost);
	if( iHealth > 0 )
		SetEntityHealth(client, iHealth);
}

stock IsValidCommon(int common)
{
	if (common > MaxClients && IsValidEdict(common) && IsValidEntity(common))
	{
		static char classname[32];
		GetEntityClassname(common, classname, sizeof(classname));
		if (StrEqual(classname, "infected"))
		{
			return true;
		}
	}	
	return false;
}

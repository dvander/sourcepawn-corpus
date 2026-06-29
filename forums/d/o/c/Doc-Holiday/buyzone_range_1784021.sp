/* Original Author: Devzirom */

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define VERSION "0.0.1"

public Plugin:myinfo = {
	name = "Buyzone Range",
	author = "SavSin",
	description = "Plugin allows to set buyzone range for: everywhere/nowhere/default",
	version = VERSION,
	url = "www.sourcemod.com"
}

new Handle:g_BuyZoneRange = INVALID_HANDLE;

public OnPluginStart() 
{
	CreateConVar("sm_bz_version", VERSION, "Version of Buyzone Range Source", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_BuyZoneRange = CreateConVar("sm_bz_range", "1", "0 = default 1 = everywhere 2 = nowhere");
	
	if(g_BuyZoneRange != INVALID_HANDLE)
	{
		HookConVarChange(g_BuyZoneRange, OnCvarChange);
	}
	
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public OnMapStart() 
{
	if(GetConVarInt(g_BuyZoneRange) == 2)
	{
		new iEnt=-1;
		while((iEnt = FindEntityByClassname(iEnt, "func_buyzone")) != -1)
		{
			AcceptEntityInput(iEnt, "Disable");
		}
	}
}

public OnCvarChange(Handle:hCVar, const String:szOld[], const String:szNew[])
{
	new iValue = StringToInt(szNew); new iEnt=-1;
	while((iEnt = FindEntityByClassname(iEnt, "func_buyzone")) != -1)
	{
		if(iValue < 2)
		{
			AcceptEntityInput(iEnt, "Enable");
		}
		else if(iValue == 2)
		{
			AcceptEntityInput(iEnt, "Disable");
		}
	}
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetConVarInt(g_BuyZoneRange) != 1 || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	SDKHook(iClient, SDKHook_Touch, OnPlayerTouch);
	return Plugin_Continue;
}

public Action:OnPlayerTouch(iClient, other)
{
	switch(GetConVarInt(g_BuyZoneRange))
	{
		case 0:
		{
			//Function normally
			SDKUnhook(iClient, SDKHook_Touch, OnPlayerTouch);
		}
		case 1:
		{
			SetEntProp(iClient, Prop_Send, "m_bInBuyZone", 1);
		}
		default:
		{
			SetEntProp(iClient, Prop_Send, "m_bInBuyZone", 0);
			SDKUnhook(iClient, SDKHook_Touch, OnPlayerTouch);
		}
	}
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKUnhook(iClient, SDKHook_Touch, OnPlayerTouch);
	return Plugin_Continue;
}
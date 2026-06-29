#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_UPDATE_URL "http://downloads.minotf.tk/sm_plugins/tf_market_crit.txt"
#define PLUGIN_VERSION "1.2.1"
#define WEAPON_INDEX_MARKET 416

new g_iCurrentEquip[MAXPLAYERS + 1];
new bool:g_bIsRocketJumping[MAXPLAYERS + 1];
new bool:g_bIsCritBoost[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[TF2] Show crit effect Market Gardener",
	author = "Mino",
	description = "Show crit boost effect while rocket jumping with market Market Gardener",
	version = PLUGIN_VERSION,
	url = "http://minotf.tk/"
};

public OnPluginStart()
{
	/* TF2 서버 검출 */
	decl String:szGameName[32];
	GetGameFolderName(szGameName, sizeof(szGameName));
	if (!(StrEqual(szGameName, "tf", false) || StrEqual(szGameName, "tf_beta", false)))
		SetFailState("SERVER IS NOT RUNNING TF2");
	
	HookEvent("rocket_jump", Event_StartJump);
	HookEvent("rocket_jump_landed", Event_EndJump);
	HookEvent("player_death", Event_PlayerWasted); // Because without this, if player dead while jumping, player get infinite crit after respawn.
		
	CreateConVar("sm_tmc_version", PLUGIN_VERSION, "[TMC] Plugin version", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY);
	
	// For late load
	for (new i = 1; i < MaxClients ; i++)
	{
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
	
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(PLUGIN_UPDATE_URL);
    }
	
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(PLUGIN_UPDATE_URL);
    }
}

public OnPluginEnd()
{
	for (new i = 1; i < MaxClients ; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && g_bIsCritBoost[i])
			TF2_RemoveCondition(i, TFCond_CritOnKill);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public OnClientDisconnect(client)
{
	DeleteStatus(client);
}

public Event_StartJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (iClient <= 0 || iClient > MaxClients)
		return;
	
	g_bIsRocketJumping[iClient] = true;
	
	if (g_iCurrentEquip[iClient] == WEAPON_INDEX_MARKET)
	{
		TF2_AddCondition(iClient, TFCond_CritOnKill, -1.0);
	}
}

public Event_EndJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (iClient <= 0 || iClient > MaxClients)
		return;
	
	if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		if (g_iCurrentEquip[iClient] == WEAPON_INDEX_MARKET)
		{
			TF2_RemoveCondition(iClient, TFCond_CritOnKill);
			g_bIsCritBoost[iClient] = false;
		}
	}
	
	g_bIsRocketJumping[iClient] = false;
}

public Event_PlayerWasted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (iClient <= 0 || iClient > MaxClients)
		return;
	
	DeleteStatus(iClient);
}


public Action:OnWeaponSwitch(client, weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	new iNextEquip = GetItemIndex(weapon);
	if (g_iCurrentEquip[client] == WEAPON_INDEX_MARKET && iNextEquip != WEAPON_INDEX_MARKET)
	{
		TF2_RemoveCondition(client, TFCond_CritOnKill);
		g_bIsCritBoost[client] = false;
	} else if (iNextEquip == WEAPON_INDEX_MARKET && g_bIsRocketJumping[client])
	{
		TF2_AddCondition(client, TFCond_CritOnKill, -1.0);
		g_bIsCritBoost[client] = true;
	}
	
	g_iCurrentEquip[client] = iNextEquip;
	return Plugin_Continue;
}

DeleteStatus(client)
{
	g_bIsRocketJumping[client] = false;
	g_iCurrentEquip[client] = 0;
	g_bIsCritBoost[client] = false;
}

GetItemIndex(entity)
{
	if (entity <= MaxClients && IsValidEntity(entity))
		return -1;
	
	return GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
}
